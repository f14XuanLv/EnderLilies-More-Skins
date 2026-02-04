/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated January 1, 2020. Replaces all prior versions.
 *
 * Copyright (c) 2013-2020, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#include "SpineEditorPluginPrivatePCH.h"

#include "SpineSkeletonDataAsset.h"
#include "AssetRegistryModule.h"
#include "AssetToolsModule.h"
#include "PackageTools.h"
#include "Developer/AssetTools/Public/IAssetTools.h"
#include "Developer/DesktopPlatform/Public/IDesktopPlatform.h"
#include "Developer/DesktopPlatform/Public/DesktopPlatformModule.h"
#include "AssetImportTask.h"
#include <string>
#include <string.h>
#include <stdlib.h>

#define LOCTEXT_NAMESPACE "Spine"

// Add helper function at the top of the file to set default properties for Lily
static void SetupLilyDefaultProperties(USpineSkeletonDataAsset* Asset, FString MainSkinName) {
    // 1. Set basic properties
    Asset->DefaultMix = 0.1f;
    Asset->DefaultScale = 1.196f;

    // 2. Set Lily standard skin array
    Asset->DefaultSkins.Empty();
    Asset->DefaultSkins.Add(TEXT("_common"));
    Asset->DefaultSkins.Add(MainSkinName); // Dynamically passed in, e.g., p0007_Lily
    Asset->DefaultSkins.Add(TEXT("_Meat_Head_0"));

    // 3. Fill 26 MixData entries
    Asset->MixData.Empty();
    auto AddMix = [&](FString From, FString To, float Mix) {
        FSpineAnimationStateMixData Data;
        Data.From = From;
        Data.To = To;
        Data.Mix = Mix;
        Asset->MixData.Add(Data);
    };

    // --- Complete 26 Mix mapping table ---
    AddMix(TEXT(""), TEXT("wall_climb_low"), 0.0f);
    AddMix(TEXT(""), TEXT("wall_climb_high"), 0.0f);
    AddMix(TEXT(""), TEXT("damage_start"), 0.0f);
    AddMix(TEXT(""), TEXT("death"), 0.0f);
    AddMix(TEXT(""), TEXT("jump_up"), 0.0f);
    AddMix(TEXT("jump_up"), TEXT("jump_apex"), 0.2f);
    AddMix(TEXT("jump_apex"), TEXT("jump_down"), 0.2f);
    AddMix(TEXT("idle_turn"), TEXT("run"), 0.2f);
    AddMix(TEXT("run_turn"), TEXT("run"), 0.05f);
    AddMix(TEXT(""), TEXT("dive_idle"), 0.3f);
    AddMix(TEXT("dive_forward"), TEXT("dive_up"), 0.4f);
    AddMix(TEXT("dive_up"), TEXT("dive_forward"), 0.4f);
    AddMix(TEXT("dive_forward"), TEXT("dive_down"), 0.4f);
    AddMix(TEXT("dive_down"), TEXT("dive_forward"), 0.4f);
    AddMix(TEXT(""), TEXT("dive_forward"), 0.2f);
    AddMix(TEXT(""), TEXT("rest_sleep_loop"), 0.0f);
    AddMix(TEXT("swim_forward"), TEXT(""), 0.4f);
    AddMix(TEXT(""), TEXT("swim_forward"), 0.3f);
    AddMix(TEXT("swim_idle"), TEXT(""), 0.2f);
    AddMix(TEXT(""), TEXT("swim_idle"), 0.5f);
    AddMix(TEXT("swim_forward"), TEXT("jump_up"), 0.0f);
    AddMix(TEXT("swim_idle"), TEXT("jump_up"), 0.0f);
    AddMix(TEXT("stumble"), TEXT("stumble_loop"), 0.1f);
    AddMix(TEXT("parry_achievement"), TEXT(""), 0.2f);
    AddMix(TEXT(""), TEXT("jump_down"), 0.2f);
    AddMix(TEXT("liberate_stand_start"), TEXT(""), 0.0f);
}

USpineSkeletonAssetFactory::USpineSkeletonAssetFactory (const FObjectInitializer& objectInitializer): Super(objectInitializer) {
	bCreateNew = false;
	bEditAfterNew = true;
	bEditorImport = true;
	SupportedClass = USpineSkeletonDataAsset::StaticClass();
	
	Formats.Add(TEXT("json;Spine skeleton file"));
	Formats.Add(TEXT("skel;Spine skeleton file"));
}

FText USpineSkeletonAssetFactory::GetToolTip () const {
	return LOCTEXT("USpineSkeletonAssetFactory", "Animations exported from Spine");
}

bool USpineSkeletonAssetFactory::FactoryCanImport (const FString& Filename) {
	return true;
}

void LoadAtlas (const FString& Filename, const FString& TargetPath) {
	FAssetToolsModule& AssetToolsModule = FModuleManager::GetModuleChecked<FAssetToolsModule>("AssetTools");
	
	FString skelFile = Filename.Replace(TEXT(".skel"), TEXT(".atlas")).Replace(TEXT(".json"), TEXT(".atlas"));
	if (!FPaths::FileExists(skelFile)) return;
	
	// Create an automated import task with bAutomated = true to disable UI
	UAssetImportTask* Task = NewObject<UAssetImportTask>();
	Task->Filename = skelFile;
	Task->DestinationPath = TargetPath;
	Task->bSave = true;
	Task->bReplaceExisting = true;
	
	// Force silent mode if running from commandlet (Python script)
	// We recommend silent import even in editor for smoother experience
	Task->bAutomated = IsRunningCommandlet() || true;

	TArray<UAssetImportTask*> Tasks;
	Tasks.Add(Task);

	AssetToolsModule.Get().ImportAssetTasks(Tasks);
}

UObject* USpineSkeletonAssetFactory::FactoryCreateFile (UClass * InClass, UObject * InParent, FName InName, EObjectFlags Flags, const FString & Filename, const TCHAR* Parms, FFeedbackContext * Warn, bool& bOutOperationCanceled) {
    // 1. Obtain the current package container directly (e.g., p0007_Lily).
    UPackage* SharedPackage = InParent->GetOutermost();
    SharedPackage->FullyLoad();

    // 2. Construct the internal object name (e.g., p0007_Lily-data).
    FString ObjectName = InName.ToString() + TEXT("-data");

    // 3. Create the SkeletonData object within the same package to achieve the original multi-object per package (.uasset) structure.
    USpineSkeletonDataAsset* asset = NewObject<USpineSkeletonDataAsset>(SharedPackage, InClass, FName(*ObjectName), Flags);
    
    // --- SDK Lily auto-alignment logic starts ---
    // Get filename without path for detection, e.g., "p0007_Lily.skel"
    FString CleanFileName = FPaths::GetCleanFilename(Filename);
    
    // Activation prerequisite: filename strictly matches p*_Lily.skel or p*_Lily.json format
    FString FileNameNoExt = FPaths::GetBaseFilename(Filename);
    bool bIsLilyFile = FileNameNoExt.StartsWith(TEXT("p")) && FileNameNoExt.EndsWith(TEXT("_Lily"))
                       && (CleanFileName.EndsWith(TEXT(".skel")) || CleanFileName.EndsWith(TEXT(".json")));
    
    if (bIsLilyFile) {
        // InName is usually the filename already (without suffix), e.g., "p0007_Lily"
        SetupLilyDefaultProperties(asset, InName.ToString());
    }
    // --- SDK Lily auto-alignment logic ends ---

    // 4. Load binary raw data
    TArray<uint8> rawData;
    if (!FFileHelper::LoadFileToArray(rawData, *Filename, 0)) {
        return nullptr;
    }
    asset->SetSkeletonDataFileName(FName(*Filename));
    asset->SetRawData(rawData);

    // 5. Auto-load associated Atlas
    const FString folderPath = FPackageName::GetLongPackagePath(SharedPackage->GetPathName());
    LoadAtlas(Filename, folderPath);
    return asset;
}

bool USpineSkeletonAssetFactory::CanReimport (UObject* Obj, TArray<FString>& OutFilenames) {
	USpineSkeletonDataAsset* asset = Cast<USpineSkeletonDataAsset>(Obj);
	if (!asset) return false;
	
	FString filename = asset->GetSkeletonDataFileName().ToString();
	if (!filename.IsEmpty())
		OutFilenames.Add(filename);
	
	return true;
}

void USpineSkeletonAssetFactory::SetReimportPaths (UObject* Obj, const TArray<FString>& NewReimportPaths) {
	USpineSkeletonDataAsset* asset = Cast<USpineSkeletonDataAsset>(Obj);
	
	if (asset && ensure(NewReimportPaths.Num() == 1))
		asset->SetSkeletonDataFileName(FName(*NewReimportPaths[0]));
}

EReimportResult::Type USpineSkeletonAssetFactory::Reimport (UObject* Obj) {
	USpineSkeletonDataAsset* asset = Cast<USpineSkeletonDataAsset>(Obj);
	TArray<uint8> rawData;
	if (!FFileHelper::LoadFileToArray(rawData, *asset->GetSkeletonDataFileName().ToString(), 0)) return EReimportResult::Failed;
	asset->SetRawData(rawData);
	
	const FString longPackagePath = FPackageName::GetLongPackagePath(asset->GetOutermost()->GetPathName());
	LoadAtlas(*asset->GetSkeletonDataFileName().ToString(), longPackagePath);
	
	if (Obj->GetOuter()) Obj->GetOuter()->MarkPackageDirty();
	else Obj->MarkPackageDirty();
	
	return EReimportResult::Succeeded;
}

#undef LOCTEXT_NAMESPACE
