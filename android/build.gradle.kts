allprojects {
    repositories {
        google()
        mavenCentral()
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
// Workaround: some older plugins (e.g. on_audio_query_android) don't declare a
// `namespace` in their build.gradle, which AGP 8+ requires. Backfill it from the
// AndroidManifest.xml `package` attribute so the build doesn't fail.
// Must be registered before evaluationDependsOn forces early evaluation below.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            if (android.namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val text = manifestFile.readText()
                    val match = Regex("package=\"([^\"]+)\"").find(text)
                    match?.groupValues?.get(1)?.let { pkg ->
                        android.namespace = pkg
                    }
                }
            }
            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
