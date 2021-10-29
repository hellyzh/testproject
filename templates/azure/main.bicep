param resourceBaseName string
param frontendHosting_storageName string = 'frontendstg${uniqueString(resourceBaseName)}'
param identity_managedIdentityName string = '${resourceBaseName}-managedIdentity'
param azureSql_admin string
@secure()
param azureSql_adminPassword string
param azureSql_serverName string = '${resourceBaseName}-sql-server'
param azureSql_databaseName string = '${resourceBaseName}-database'
param bot_aadClientId string
@secure()
param bot_aadClientSecret string
param bot_serviceName string = '${resourceBaseName}-bot-service'
param bot_displayName string = '${resourceBaseName}-bot-displayname'
param bot_serverfarmsName string = '${resourceBaseName}-bot-serverfarms'
param bot_webAppSKU string = 'B1'
param bot_serviceSKU string = 'B1'
param bot_sitesName string = '${resourceBaseName}-bot-sites'
param authLoginUriSuffix string = 'auth-start.html'
param m365ClientId string
@secure()
param m365ClientSecret string
param m365TenantId string
param m365OauthAuthorityHost string
param function_serverfarmsName string = '${resourceBaseName}-function-serverfarms'
param function_webappName string = '${resourceBaseName}-function-webapp'
param function_storageName string = 'functionstg${uniqueString(resourceBaseName)}'
param simpleAuth_sku string = 'B1'
param simpleAuth_serverFarmsName string = '${resourceBaseName}-simpleAuth-serverfarms'
param simpleAuth_webAppName string = '${resourceBaseName}-simpleAuth-webapp'
param simpleAuth_packageUri string = 'https://github.com/OfficeDev/TeamsFx/releases/download/simpleauth@0.1.0/Microsoft.TeamsFx.SimpleAuth_0.1.0.zip'
param customizedRg string = 'helly10281701-dev-rg'

var m365ApplicationIdUri = 'api://${frontendHostingProvision.outputs.domain}/botid-${bot_aadClientId}'

module frontendHostingProvision './modules/frontendHostingProvision.bicep' = {
  name: 'frontendHostingProvision'
  scope: resourceGroup(customizedRg)
  params: {
    frontendHostingStorageName: frontendHosting_storageName
  }
}
module userAssignedIdentityProvision './modules/userAssignedIdentityProvision.bicep' = {
  name: 'userAssignedIdentityProvision'
  params: {
    managedIdentityName: identity_managedIdentityName
  }
}
module azureSqlProvision './modules/azureSqlProvision.bicep' = {
  name: 'azureSqlProvision'
  scope: resourceGroup(customizedRg)
  params: {
    sqlServerName: azureSql_serverName
    sqlDatabaseName: azureSql_databaseName
    administratorLogin: azureSql_admin
    administratorLoginPassword: azureSql_adminPassword
  }
}
module botProvision './modules/botProvision.bicep' = {
  name: 'botProvision'
  scope: resourceGroup(customizedRg)
  params: {
    botServerfarmsName: bot_serverfarmsName
    botServiceName: bot_serviceName
    botAadClientId: bot_aadClientId
    botDisplayName: bot_displayName
    botServiceSKU: bot_serviceSKU
    botWebAppName: bot_sitesName
    botWebAppSKU: bot_webAppSKU
    identityResourceId: userAssignedIdentityProvision.outputs.identityResourceId
  }
}
module botConfiguration './modules/botConfiguration.bicep' = {
  name: 'botConfiguration'
  scope: resourceGroup(customizedRg)
  dependsOn: [
    botProvision
  ]
  params: {
    botAadClientId: bot_aadClientId
    botAadClientSecret: bot_aadClientSecret
    botServiceName: bot_serviceName
    botWebAppName: bot_sitesName
    authLoginUriSuffix: authLoginUriSuffix
    botEndpoint: botProvision.outputs.botWebAppEndpoint
    m365ApplicationIdUri: m365ApplicationIdUri
    m365ClientId: m365ClientId
    m365ClientSecret: m365ClientSecret
    m365TenantId: m365TenantId
    m365OauthAuthorityHost: m365OauthAuthorityHost
    functionEndpoint: functionProvision.outputs.functionEndpoint
    sqlDatabaseName: azureSqlProvision.outputs.databaseName
    sqlEndpoint: azureSqlProvision.outputs.sqlEndpoint
    identityClientId: userAssignedIdentityProvision.outputs.identityClientId
  }
}
module functionProvision './modules/functionProvision.bicep' = {
  name: 'functionProvision'
  scope: resourceGroup(customizedRg)
  params: {
    functionAppName: function_webappName
    functionServerfarmsName: function_serverfarmsName
    functionStorageName: function_storageName
    identityResourceId: userAssignedIdentityProvision.outputs.identityResourceId
  }
}
module functionConfiguration './modules/functionConfiguration.bicep' = {
  name: 'functionConfiguration'
  scope: resourceGroup(customizedRg)
  dependsOn: [
    functionProvision
  ]
  params: {
    functionAppName: function_webappName
    functionStorageName: function_storageName
    m365ClientId: m365ClientId
    m365ClientSecret: m365ClientSecret
    m365TenantId: m365TenantId
    m365ApplicationIdUri: m365ApplicationIdUri
    m365OauthAuthorityHost: m365OauthAuthorityHost
    frontendHostingStorageEndpoint: frontendHostingProvision.outputs.endpoint
    sqlDatabaseName: azureSqlProvision.outputs.databaseName
    sqlEndpoint: azureSqlProvision.outputs.sqlEndpoint
    identityClientId: userAssignedIdentityProvision.outputs.identityClientId
  }
}
module simpleAuthProvision './modules/simpleAuthProvision.bicep' = {
  name: 'simpleAuthProvision'
  params: {
    simpleAuthServerFarmsName: simpleAuth_serverFarmsName
    simpleAuthWebAppName: simpleAuth_webAppName
    sku: simpleAuth_sku
  }
}
module simpleAuthConfiguration './modules/simpleAuthConfiguration.bicep' = {
  name: 'simpleAuthConfiguration'
  dependsOn: [
    simpleAuthProvision
  ]
  params: {
    simpleAuthWebAppName: simpleAuth_webAppName
    m365ClientId: m365ClientId
    m365ClientSecret: m365ClientSecret
    m365ApplicationIdUri: m365ApplicationIdUri
    frontendHostingStorageEndpoint: frontendHostingProvision.outputs.endpoint
    m365TenantId: m365TenantId
    oauthAuthorityHost: m365OauthAuthorityHost
    simpleAuthPackageUri: simpleAuth_packageUri
  }
}

output frontendHosting_storageResourceId string = frontendHostingProvision.outputs.resourceId
output frontendHosting_endpoint string = frontendHostingProvision.outputs.endpoint
output frontendHosting_domain string = frontendHostingProvision.outputs.domain
output identity_identityName string = userAssignedIdentityProvision.outputs.identityName
output identity_identityClientId string = userAssignedIdentityProvision.outputs.identityClientId
output identity_identityResourceId string = userAssignedIdentityProvision.outputs.identityResourceId
output azureSql_sqlResourceId string = azureSqlProvision.outputs.resourceId
output azureSql_sqlEndpoint string = azureSqlProvision.outputs.sqlEndpoint
output azureSql_databaseName string = azureSqlProvision.outputs.databaseName
output bot_webAppSKU string = botProvision.outputs.botWebAppSKU
output bot_serviceSKU string = botProvision.outputs.botServiceSKU
output bot_webAppName string = botProvision.outputs.botWebAppName
output bot_webAppResourceId string = botProvision.outputs.botWebAppResourceId
output bot_domain string = botProvision.outputs.botDomain
output bot_appServicePlanName string = botProvision.outputs.appServicePlanName
output bot_serviceName string = botProvision.outputs.botServiceName
output bot_webAppEndpoint string = botProvision.outputs.botWebAppEndpoint
output function_functionEndpoint string = functionProvision.outputs.functionEndpoint
output function_appResourceId string = functionProvision.outputs.functionAppResourceId
output simpleAuth_skuName string = simpleAuthProvision.outputs.skuName
output simpleAuth_endpoint string = simpleAuthProvision.outputs.endpoint
output simpleAuth_webAppName string = simpleAuthProvision.outputs.webAppName
output simpleAuth_appServicePlanName string = simpleAuthProvision.outputs.appServicePlanName