#!/bin/bash

# This pre-commit hook will convert any staged PNG files to lossless WebP and
# stage them to be committed. This happens automatically without any
# intervention required.
#
# If the developer does not have `cwebp` installed we will block the commit
# and print a helpful error message.

# Make sure cwebp is installed.
if ! type "cwebp" > /dev/null; then
    echo "Please install cwebp to continue:"
    echo "brew install webp"
    exit 1
fi

echo "Converting PNGs to WebP."

# Get PNG files from the diff. We exclude 9patch images and
# the app icon which must be a PNG.
changed_png_files=($(git diff --cached --name-only --diff-filter=ACMR \
    | grep ".*\.png$" \
    | grep -v "\.9\.png$" \
    | grep -v ".*app_icon.png" \
    | sed "s:^:${root_dir}/:"))

for path in "${changed_png_files[@]}"; do
    png_file_path=".${path}"
    echo "Converting ${png_file_path}"

    # Remove .png and add .webp.
    webp_file_path="${png_file_path::${#png_file_path}-4}.webp"

    # Does the actual conversion. Details on arguments:
    # https://gist.githubusercontent.com/coltin/30ed428a04b10e99329d9e85c79de0c1/raw/f71137b8b2e254138d68678548b87292977e5bb6/cwebp_arguments_1.txt
    cwebp -pass 10 -mt -alpha_filter best -alpha_cleanup -m 6 -quiet -lossless "${png_file_path}" -o "${webp_file_path}"

    # Delete the actual PNG file.
    rm "${png_file_path}"

    # Stage the deleted PNG and new WebP file to git.
    # Since this is part of the pre-commit hook it will add these files
    # to the commit.
    git add "${png_file_path}" "${webp_file_path}"
done

echo "Image conversion finished."