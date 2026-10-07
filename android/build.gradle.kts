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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun configure() {
        project.extensions.findByName("android")?.let { ext ->
            for (m in ext.javaClass.methods) {
                if (m.name in listOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk")) {
                    if (m.parameterTypes.size == 1) {
                        try {
                            val paramType = m.parameterTypes[0]
                            if (paramType == Int::class.javaPrimitiveType || paramType == java.lang.Integer::class.java) {
                                m.invoke(ext, 36)
                                break
                            } else if (paramType == String::class.java) {
                                m.invoke(ext, "android-36")
                                break
                            }
                        } catch (_: Throwable) {}
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        configure()
    } else {
        project.afterEvaluate { configure() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
