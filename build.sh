set -e

task="$1"

WORKSPACE_NAME="IBDemo.xcworkspace"

#Create zip file with binary and doc
if [ "$task" == "-d" ]; then
        xcodebuild clean test -workspace "${WORKSPACE_NAME}" -scheme "IBKitTests" -sdk "iphonesimulator9.3" -destination "OS=9.3,name=iPhone 6 Plus" -configuration Debug 
        if [${PIPESTATUS[0]} == true]; then
        	exit ${PIPESTATUS[0]}
        fi
        
        xcodebuild -workspace "${WORKSPACE_NAME}" -scheme "BuildFatFramework"
        xcodebuild -workspace "${WORKSPACE_NAME}" -scheme "Documentation"
        zip -r IBKit-Deliverable.zip IBKit.framework docs/ README.md OTAnnotationKitBundle.bundle 
fi