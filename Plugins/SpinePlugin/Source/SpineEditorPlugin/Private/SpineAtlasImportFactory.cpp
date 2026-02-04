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

#include "SpineAtlasAsset.h"
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

using namespace spine;

USpineAtlasAssetFactory::USpineAtlasAssetFactory (const FObjectInitializer& objectInitializer): Super(objectInitializer) {
	bCreateNew = false;
	bEditAfterNew = true;
	bEditorImport = true;
	SupportedClass = USpineAtlasAsset::StaticClass();
	
	Formats.Add(TEXT("atlas;Spine Atlas file"));
}

FText USpineAtlasAssetFactory::GetToolTip () const {
	return LOCTEXT("SpineAtlasAssetFactory", "Animations exported from Spine");
}

bool USpineAtlasAssetFactory::FactoryCanImport (const FString& Filename) {
	return true;
}

UObject* USpineAtlasAssetFactory::FactoryCreateFile (UClass * InClass, UObject * InParent, FName InName, EObjectFlags Flags, const FString & Filename, const TCHAR* Parms, FFeedbackContext * Warn, bool& bOutOperationCanceled) {
    FString rawString;
    if (!FFileHelper::LoadFileToString(rawString, *Filename)) {
        return nullptr;
    }

    // 1. Get the path of the folder currently being imported into (e.g., .../Characters/p0007_Lily).
    const FString folderPath = FPackageName::GetLongPackagePath(InParent->GetOutermost()->GetPathName());
    
    // 2. Resolve the full package path. Note: InName is already the filename (e.g., "p0007_Lily"). 
    // Use InParent as the package container directly to avoid creating redundant sub-folders.
    UPackage* SharedPackage = InParent->GetOutermost();
    SharedPackage->FullyLoad();

    // 3. Construct the internal object name (e.g., p0007_Lily-atlas).
    FString ObjectName = InName.ToString() + TEXT("-atlas");

    // 4. Create the asset object, ensuring its Outer is the package itself to allow a multi-object asset structure.
    USpineAtlasAsset* asset = NewObject<USpineAtlasAsset>(SharedPackage, InClass, FName(*ObjectName), Flags);
    asset->SetRawData(rawString);
    asset->SetAtlasFileName(FName(*Filename));

    FString currentSourcePath, filenameNoExtension, unusedExtension;
    FPaths::Split(Filename, currentSourcePath, filenameNoExtension, unusedExtension);

    LoadAtlas(asset, currentSourcePath, folderPath); 
    return asset;
}

bool USpineAtlasAssetFactory::CanReimport (UObject* Obj, TArray<FString>& OutFilenames) {
	USpineAtlasAsset* asset = Cast<USpineAtlasAsset>(Obj);
	if (!asset) return false;
	
	FString filename = asset->GetAtlasFileName().ToString();
	if (!filename.IsEmpty())
		OutFilenames.Add(filename);
	
	return true;
}

void USpineAtlasAssetFactory::SetReimportPaths (UObject* Obj, const TArray<FString>& NewReimportPaths) {
	USpineAtlasAsset* asset = Cast<USpineAtlasAsset>(Obj);
	
	if (asset && ensure(NewReimportPaths.Num() == 1))
		asset->SetAtlasFileName(FName(*NewReimportPaths[0]));
}

EReimportResult::Type USpineAtlasAssetFactory::Reimport (UObject* Obj) {
	USpineAtlasAsset* asset = Cast<USpineAtlasAsset>(Obj);
	FString rawString;
	if (!FFileHelper::LoadFileToString(rawString, *asset->GetAtlasFileName().ToString())) return EReimportResult::Failed;
	asset->SetRawData(rawString);
	
	FString currentSourcePath, filenameNoExtension, unusedExtension;
	const FString longPackagePath = FPackageName::GetLongPackagePath(asset->GetOutermost()->GetPathName());
	FString currentFileName = asset->GetAtlasFileName().ToString();
	FPaths::Split(currentFileName, currentSourcePath, filenameNoExtension, unusedExtension);
	
	LoadAtlas(asset, currentSourcePath, longPackagePath);
	
	if (Obj->GetOuter()) Obj->GetOuter()->MarkPackageDirty();
	else Obj->MarkPackageDirty();
	
	return EReimportResult::Succeeded;
}

UTexture2D* resolveTexture (USpineAtlasAsset* Asset, const FString& PageFileName, const FString& TargetSubPath) {
    // 1. Calculate the expected internal project path for the texture.
    FString TextureName = FPaths::GetBaseFilename(PageFileName);
    FString FullDestPath = TargetSubPath / TextureName;

    // 2. Check if the texture asset already exists.
    UTexture2D* texture = Cast<UTexture2D>(StaticLoadObject(UTexture2D::StaticClass(), nullptr, *FullDestPath));

    // 3. If not exists, perform import.
    if (!texture) {
        FAssetToolsModule& AssetToolsModule = FModuleManager::GetModuleChecked<FAssetToolsModule>("AssetTools");
        TArray<FString> fileNames;
        fileNames.Add(PageFileName);

        // Use Task mode to support commandlet (script) execution
        UAssetImportTask* Task = NewObject<UAssetImportTask>();
        Task->Filename = PageFileName;
        Task->DestinationPath = TargetSubPath;
        Task->bAutomated = true; // Force silent mode to prevent commandlet crashes
        Task->bSave = true;
        Task->bReplaceExisting = true;

        TArray<UAssetImportTask*> Tasks;
        Tasks.Add(Task);
        AssetToolsModule.Get().ImportAssetTasks(Tasks);

        // Try to get the imported object again
        texture = Cast<UTexture2D>(StaticLoadObject(UTexture2D::StaticClass(), nullptr, *FullDestPath));
    }

    // --- Core optimization: Enforce Lily texture properties ---
    if (texture) {
        FString AtlasName = Asset->GetName(); // Get the name of the Atlas asset being imported
        
        // Rule: Asset name starts with 'p' AND contains 'Lily' (e.g. p0007_Lily-atlas)
        if (AtlasName.StartsWith(TEXT("p")) && AtlasName.Contains(TEXT("Lily"))) {
            bool bModified = false;

            // Set no mipmaps
            if (texture->MipGenSettings != TMGS_NoMipmaps) {
                texture->MipGenSettings = TMGS_NoMipmaps;
                bModified = true;
            }

            // Set Character LOD Group
            if (texture->LODGroup != TEXTUREGROUP_Character) {
                texture->LODGroup = TEXTUREGROUP_Character;
                bModified = true;
            }

            if (bModified) {
                texture->Modify(); // Mark object as modified
                texture->PostEditChange(); // Notify engine that properties have changed (this rebuilds texture resources)
            }
        }
    }

    return texture;
}

void USpineAtlasAssetFactory::LoadAtlas (USpineAtlasAsset* Asset, const FString& CurrentSourcePath, const FString& LongPackagePath) {
	Atlas* atlas = Asset->GetAtlas();
	Asset->atlasPages.Empty();
	
	const FString targetTexturePath = LongPackagePath / TEXT("Textures");
	
	Vector<AtlasPage*> &pages = atlas->getPages();
	for (size_t i = 0, n = pages.size(); i < n; i++) {
		AtlasPage* page = pages[i];
		const FString sourceTextureFilename = FPaths::Combine(*CurrentSourcePath, UTF8_TO_TCHAR(page->name.buffer()));
		UTexture2D* texture = resolveTexture(Asset, sourceTextureFilename, targetTexturePath);
		Asset->atlasPages.Add(texture);
	}
}

#undef LOCTEXT_NAMESPACE
