set -o errexit

[[ -z "$BUILD_STYLE" ]] && BUILD_STYLE=$CONFIGURATION

[ $BUILD_STYLE = Release ] || { echo Distribution target requires "'Release'" build style; false; }

VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info" CFBundleShortVersionString)
ARCHIVE_FILENAME="$PROJECT_NAME-$VERSION.zip"
WD=$PWD

cd "$BUILT_PRODUCTS_DIR"

rm -f "$PROJECT_NAME"*.zip
ditto -ck --keepParent "$PROJECT_NAME.app" "$ARCHIVE_FILENAME"

mv "$ARCHIVE_FILENAME" "$WD/site/updates/"
