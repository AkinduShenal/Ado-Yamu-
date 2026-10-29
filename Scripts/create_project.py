"""Regenerates the dependency-free Xcode project; preserves source files."""
import hashlib, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'AdoYamu.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}
def uid(value): return hashlib.sha1(value.encode()).hexdigest()[:24].upper()
def add(key, value): objects[uid(key)] = value; return uid(key)
def q(s): return '"' + str(s).replace('\\','\\\\').replace('"','\\"') + '"'
def array(values): return '(' + ', '.join(values) + ')'
def obj(**kw): return '{ ' + ' '.join(f'{k} = {v};' for k,v in kw.items()) + ' }'
products = []
groups = []
for name, folder, product_type, ext in [('AdoYamu','AdoYamu','com.apple.product-type.application','app'), ('AdoYamuTests','AdoYamuTests','com.apple.product-type.bundle.unit-test','xctest'), ('AdoYamuUITests','AdoYamuUITests','com.apple.product-type.bundle.ui-testing','xctest')]:
    files = sorted((ROOT/folder).rglob('*.swift'))
    source_builds, resource_builds, children = [], [], []
    for file in files:
        path = file.relative_to(ROOT).as_posix()
        ref = add('file:'+path, obj(isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path=q(path), sourceTree='SOURCE_ROOT'))
        children.append(ref)
        source_builds.append(add('build:'+path, obj(isa='PBXBuildFile', fileRef=ref)))
    if name == 'AdoYamu':
        for path, kind in [('AdoYamu/Resources/Assets.xcassets','folder.assetcatalog'), ('AdoYamu/Resources/LaunchScreen.storyboard','file.storyboard'), ('AdoYamu/Resources/PhotoCredits.json','text.json'), ('AdoYamu/Resources/PrivacyInfo.xcprivacy','text.xml'), ('AdoYamu/Resources/Localizable.xcstrings','text.json.xcstrings')]:
            ref=add('file:'+path,obj(isa='PBXFileReference',lastKnownFileType=kind,path=q(path),sourceTree='SOURCE_ROOT')); children.append(ref)
            resource_builds.append(add('build:'+path,obj(isa='PBXBuildFile',fileRef=ref)))
    groups.append(add('group:'+name,obj(isa='PBXGroup',children=array(children),name=q(name),sourceTree=q('<group>'))))
    product = add('product:'+name,obj(isa='PBXFileReference',explicitFileType='wrapper.application' if ext=='app' else 'wrapper.cfbundle',includeInIndex='0',path=q(name+'.'+ext),sourceTree='BUILT_PRODUCTS_DIR')); products.append(product)
    src=add('sources:'+name,obj(isa='PBXSourcesBuildPhase',buildActionMask='2147483647',files=array(source_builds),runOnlyForDeploymentPostprocessing='0'))
    res=add('resources:'+name,obj(isa='PBXResourcesBuildPhase',buildActionMask='2147483647',files=array(resource_builds),runOnlyForDeploymentPostprocessing='0'))
    framework=add('frameworks:'+name,obj(isa='PBXFrameworksBuildPhase',buildActionMask='2147483647',files='()',runOnlyForDeploymentPostprocessing='0'))
    configs=[]
    for mode in ['Debug','Release']:
        settings={'PRODUCT_NAME':q('$(TARGET_NAME)'), 'PRODUCT_BUNDLE_IDENTIFIER':q('lk.adoyamu.app' + ('' if name=='AdoYamu' else '.'+name)), 'SWIFT_VERSION':'5.0', 'IPHONEOS_DEPLOYMENT_TARGET':'17.0', 'TARGETED_DEVICE_FAMILY':q('1,2'), 'CODE_SIGN_STYLE':'Automatic', 'GENERATE_INFOPLIST_FILE':'YES', 'SWIFT_EMIT_LOC_STRINGS':'YES'}
        if name=='AdoYamu': settings.update({'GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':q('AdoYamu/Resources/Info.plist'),'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME':'AccentColor','ENABLE_PREVIEWS':'YES'})
        elif name=='AdoYamuTests': settings.update({'TEST_HOST':q('$(BUILT_PRODUCTS_DIR)/AdoYamu.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/AdoYamu'),'BUNDLE_LOADER':q('$(TEST_HOST)')})
        else: settings['TEST_TARGET_NAME']='AdoYamu'
        configs.append(add('config:'+name+mode,obj(isa='XCBuildConfiguration',buildSettings=obj(**settings),name=mode)))
    cfg=add('configs:'+name,obj(isa='XCConfigurationList',buildConfigurations=array(configs),defaultConfigurationIsVisible='0',defaultConfigurationName='Release'))
    deps=[]
    if name!='AdoYamu':
        proxy=add('proxy:'+name,obj(isa='PBXContainerItemProxy',containerPortal=uid('project'),proxyType='1',remoteGlobalIDString=uid('target:AdoYamu'),remoteInfo='AdoYamu'))
        deps=[add('dependency:'+name,obj(isa='PBXTargetDependency',target=uid('target:AdoYamu'),targetProxy=proxy))]
    add('target:'+name,obj(isa='PBXNativeTarget',buildConfigurationList=cfg,buildPhases=array([src,framework,res]),buildRules='()',dependencies=array(deps),name=q(name),productName=q(name),productReference=product,productType=q(product_type)))
prodgroup=add('products',obj(isa='PBXGroup',children=array(products),name='Products',sourceTree=q('<group>')))
main=add('main',obj(isa='PBXGroup',children=array(groups+[prodgroup]),sourceTree=q('<group>')))
configs=[]
for mode in ['Debug','Release']:
    s={'SDKROOT':'iphoneos','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','ENABLE_USER_SCRIPT_SANDBOXING':'YES','GCC_C_LANGUAGE_STANDARD':'gnu17','SWIFT_OPTIMIZATION_LEVEL':q('-Onone' if mode=='Debug' else '-O'),'DEBUG_INFORMATION_FORMAT':q('dwarf' if mode=='Debug' else 'dwarf-with-dsym'),'SWIFT_COMPILATION_MODE':'singlefile' if mode=='Debug' else 'wholemodule','ONLY_ACTIVE_ARCH':'YES' if mode=='Debug' else 'NO'}
    if mode=='Debug': s.update({'ENABLE_TESTABILITY':'YES','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG'})
    configs.append(add('projectconfig:'+mode,obj(isa='XCBuildConfiguration',buildSettings=obj(**s),name=mode)))
configlist=add('projectconfigs',obj(isa='XCConfigurationList',buildConfigurations=array(configs),defaultConfigurationIsVisible='0',defaultConfigurationName='Release'))
add('project',obj(isa='PBXProject',attributes='{ BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; }',buildConfigurationList=configlist,compatibilityVersion=q('Xcode 14.0'),developmentRegion='en',hasScannedForEncodings='0',knownRegions='(en, Base)',mainGroup=main,productRefGroup=prodgroup,projectDirPath=q(''),projectRoot=q(''),targets=array([uid('target:'+n) for n in ['AdoYamu','AdoYamuTests','AdoYamuUITests']])))
(PROJECT/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(k+' = '+v+';' for k,v in objects.items())+'\n}; rootObject = '+uid('project')+'; }\n')
scheme=PROJECT/'xcshareddata/xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
def ref(name): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:"+name)}" BuildableName="{name}.{ "app" if name=="AdoYamu" else "xctest" }" BlueprintName="{name}" ReferencedContainer="container:AdoYamu.xcodeproj"/>'
(scheme/'AdoYamu.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('AdoYamu')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('AdoYamuTests')}</TestableReference><TestableReference skipped="NO">{ref('AdoYamuUITests')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('AdoYamu')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('AdoYamu')}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
print('Created AdoYamu.xcodeproj with app, unit tests and UI tests')
