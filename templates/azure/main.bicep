param resourceBaseName string
param frontendHosting_storageName string = 'frontendstg${uniqueString(resourceBaseName)}'
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
param simpleAuth_sku string = 'B1'
param simpleAuth_serverFarmsName string = '${resourceBaseName}-simpleAuth-serverfarms'
param simpleAuth_webAppName string = '${resourceBaseName}-simpleAuth-webapp'
param simpleAuth_packageUri string = 'https://github.com/OfficeDev/TeamsFx/releases/download/simpleauth@0.1.0/Microsoft.TeamsFx.SimpleAuth_0.1.0.zip'

var m365ApplicationIdUri = 'api://${frontendHostingProvision.outputs.domain}/botid-${bot_aadClientId}'

module frontendHostingProvision './modules/frontendHostingProvision.bicep' = {
  name: 'frontendHostingProvision'
  params: {
    frontendHostingStorageName: frontendHosting_storageName
  }
}
module botProvision './modules/botProvision.bicep' = {
  name: 'botProvision'
  params: {
    botServerfarmsName: bot_serverfarmsName
    botServiceName: bot_serviceName
    botAadClientId: bot_aadClientId
    botDisplayName: bot_displayName
    botServiceSKU: bot_serviceSKU
    botWebAppName: bot_sitesName
    botWebAppSKU: bot_webAppSKU
  }
}
module botConfiguration './modules/botConfiguration.bicep' = {
  name: 'botConfiguration'
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
    simpelAuthPackageUri: simpleAuth_packageUri
  }
}

output frontendHosting_storageResourceId string = frontendHostingProvision.outputs.resourceId
output frontendHosting_endpoint string = frontendHostingProvision.outputs.endpoint
output frontendHosting_domain string = frontendHostingProvision.outputs.domain
output bot_webAppSKU string = botProvision.outputs.botWebAppSKU
output bot_serviceSKU string = botProvision.outputs.botServiceSKU
output bot_webAppName string = botProvision.outputs.botWebAppName
output bot_webAppResourceId string = botProvision.outputs.botWebAppResourceId
output bot_domain string = botProvision.outputs.botDomain
output bot_appServicePlanName string = botProvision.outputs.appServicePlanName
output bot_serviceName string = botProvision.outputs.botServiceName
output bot_webAppEndpoint string = botProvision.outputs.botWebAppEndpoint
output simpleAuth_skuName string = simpleAuthProvision.outputs.skuName
output simpleAuth_endpoint string = simpleAuthProvision.outputs.endpoint
output simpleAuth_webAppName string = simpleAuthProvision.outputs.webAppName
output simpleAuth_appServicePlanName string = simpleAuthProvision.outputs.appServicePlanName