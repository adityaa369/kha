import os

file_path = 'android/app/build.gradle.kts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

flavor_config = """    flavorDimensions += "env"

    productFlavors {
        create("production") {
            dimension = "env"
            resValue("string", "app_name", "Khataa")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Khataa Staging")
        }
    }
"""
if "flavorDimensions" not in content:
    content = content.replace("buildTypes {", flavor_config + "\n    buildTypes {")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected productFlavors into Android build.gradle.kts")
