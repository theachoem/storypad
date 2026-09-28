allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// super_editor depends on super_keyboard, whose android/build.gradle still pins compileSdk 34, while
// flutter_plugin_android_lifecycle (another transitive dependency) requires every module depending on it to compile
// against 36+ -- AGP's checkAarMetadata task fails the build otherwise. Those plugins live in the pub cache, so raise
// compileSdk here for every Android library module instead. Must be registered before `evaluationDependsOn(":app")`
// below, and use `afterEvaluate` so it runs after each plugin's own `compileSdk = 34` line.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { android ->
            if ((android.compileSdk ?: 0) < 36) {
                android.compileSdk = 36
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
