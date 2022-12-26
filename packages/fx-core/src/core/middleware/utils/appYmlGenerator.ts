// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { AzureSolutionSettings, ProjectSettings } from "@microsoft/teamsfx-api";
import { FileType, namingConverterV3 } from "./MigrationUtils";
import * as path from "path";
import * as fs from "fs-extra";
import * as handlebars from "handlebars";
import { getTemplatesFolder } from "../../../folder";
import { DebugPlaceholderMapping } from "./debug/debugV3MigrationUtils";

export abstract class BaseAppYmlGenerator {
  protected abstract handlebarsContext: any;
  constructor(protected oldProjectSettings: ProjectSettings) {}

  protected async buildHandlebarsTemplate(templateName: string): Promise<string> {
    const templatePath = path.join(getTemplatesFolder(), "core/v3Migration", templateName);
    const templateString = await fs.readFile(templatePath, "utf8");
    const template = handlebars.compile(templateString);
    return template(this.handlebarsContext);
  }
}

export class AppYmlGenerator extends BaseAppYmlGenerator {
  protected handlebarsContext: {
    activePlugins: Record<string, boolean>;
    placeholderMappings: Record<string, string>;
    aadAppName: string | undefined;
    teamsAppName: string | undefined;
    appName: string | undefined;
    isFunctionBot: boolean;
    isTypescript: boolean;
    defaultFunctionName: string | undefined;
  };
  constructor(
    oldProjectSettings: ProjectSettings,
    private bicepContent: string,
    private projectPath: string
  ) {
    super(oldProjectSettings);
    this.handlebarsContext = {
      activePlugins: {},
      placeholderMappings: {},
      aadAppName: undefined,
      teamsAppName: undefined,
      appName: undefined,
      isFunctionBot: false,
      isTypescript: false,
      defaultFunctionName: undefined,
    };
  }

  public async generateAppYml(): Promise<string> {
    await this.generateCommonHandlerbarsContext();

    const solutionSettings = this.oldProjectSettings.solutionSettings as AzureSolutionSettings;
    if (solutionSettings.hostType.toLowerCase() === "azure") {
      await this.generateAzureHandlebarsContext();
      switch (this.oldProjectSettings.programmingLanguage?.toLowerCase()) {
        case "javascript":
        case "typescript":
          return await this.buildHandlebarsTemplate("js.ts.app.yml");
        case "csharp":
          return await this.buildHandlebarsTemplate("csharp.app.yml");
      }
    } else if (solutionSettings.hostType.toLowerCase() === "spfx") {
      return await this.buildHandlebarsTemplate("spfx.app.yml");
    }
    throw new Error(
      "The current tooling cannot upgrade your project temporary. Please raise an issue in GitHub for your project."
    );
  }

  public async generateAppLocalYml(placeholderMappings: DebugPlaceholderMapping): Promise<string> {
    this.handlebarsContext.placeholderMappings = placeholderMappings as any;
    await this.generateAzureHandlebarsContext();

    const solutionSettings = this.oldProjectSettings.solutionSettings as AzureSolutionSettings;
    if (solutionSettings.hostType === "Azure") {
      switch (this.oldProjectSettings.programmingLanguage?.toLowerCase()) {
        case "csharp":
          return await this.buildHandlebarsTemplate("csharp.app.local.yml");
      }
    }
    throw new Error(
      "The current tooling cannot upgrade your project temporary. Please raise an issue in GitHub for your project."
    );
  }

  private async generateCommonHandlerbarsContext(): Promise<void> {
    // project setting information
    this.handlebarsContext.appName = this.oldProjectSettings.appName;

    const azureSolutionSettings = this.oldProjectSettings.solutionSettings as AzureSolutionSettings;
    for (const activePlugin of azureSolutionSettings.activeResourcePlugins) {
      this.handlebarsContext.activePlugins[activePlugin] = true; // convert array items to object properties to simplify handlebars template
    }

    // app names
    const aadManifestPath = path.join(this.projectPath, "aad.manifest.template.json");
    if (await fs.pathExists(aadManifestPath)) {
      const aadManifest = await fs.readJson(
        path.join(this.projectPath, "aad.manifest.template.json")
      );
      this.handlebarsContext.aadAppName = aadManifest.name;
    }

    const teamsAppManifestPath = path.join(this.projectPath, "appPackage/manifest.template.json");
    if (await fs.pathExists(teamsAppManifestPath)) {
      const teamsAppManifest = await fs.readJson(
        path.join(this.projectPath, "appPackage/manifest.template.json")
      );
      this.handlebarsContext.teamsAppName = teamsAppManifest.name.short;
    }

    // programming language
    this.handlebarsContext.isTypescript =
      this.oldProjectSettings.programmingLanguage?.toLowerCase() === "typescript";

    // default function name
    this.handlebarsContext.defaultFunctionName = this.oldProjectSettings.defaultFunctionName;
  }

  private async generateAzureHandlebarsContext(): Promise<void> {
    // isFunctionBot
    const pluginSettings = this.oldProjectSettings.pluginSettings;
    if (
      pluginSettings &&
      pluginSettings["fx-resource-bot"] &&
      pluginSettings["fx-resource-bot"]["host-type"] === "azure-function"
    ) {
      this.handlebarsContext.isFunctionBot = true;
    }

    // placeholders
    this.setPlaceholderMapping("state.fx-resource-frontend-hosting.storageResourceId");
    this.setPlaceholderMapping("state.fx-resource-frontend-hosting.endpoint");
    this.setPlaceholderMapping("state.fx-resource-frontend-hosting.resourceId");
    this.setPlaceholderMapping("state.fx-resource-frontend-hosting.indexPath");
    this.setPlaceholderMapping("state.fx-resource-bot.resourceId");
    this.setPlaceholderMapping("state.fx-resource-bot.functionAppResourceId");
    this.setPlaceholderMapping("state.fx-resource-function.functionAppResourceId");
    this.setPlaceholderMapping("state.fx-resource-function.functionEndpoint");
  }

  private setPlaceholderMapping(placeholder: string): void {
    const result = namingConverterV3(placeholder, FileType.STATE, this.bicepContent);
    if (result.isOk()) {
      this.handlebarsContext.placeholderMappings[placeholder] = result.value;
    }
    // ignore non-exist placeholder
  }
}
