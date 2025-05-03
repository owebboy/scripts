#!/bin/bash

# portrait_to_landscape.sh - Convert portrait images to landscape by adding black bars
# Run directly with: curl -s https://raw.githubusercontent.com/owebboy/scripts/refs/heads/main/portrait_to_landscape.sh | bash -s -- [options]

# Version information
VERSION="1.0.0"
SCRIPT_NAME="portrait_to_landscape.sh"
SCRIPT_URL="https://raw.githubusercontent.com/owebboy/scripts/refs/heads/main/portrait_to_landscape.sh"

# Default values
INPUT_FOLDER="."
OUTPUT_FOLDER="./landscape_output"
TARGET_WIDTH=1920
TARGET_HEIGHT=1080
RECURSIVE=false
PAD_COLOR="black"
FORCE_ALL=false

# Display help message
show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION - Convert portrait images to landscape format with padding

Usage: curl -s $SCRIPT_URL | bash -s -- [options]
   or: $0 [options]

Options:
  -i, --input DIR      Input directory (default: current directory)
  -o, --output DIR     Output directory (default: ./landscape_output)
  -w, --width NUM      Target width (default: 1920)
  -h, --height NUM     Target height (default: 1080)
  -r, --recursive      Process subdirectories recursively
  -c, --color COLOR    Padding color (default: black)
  -f, --force-all      Process all images, not just portrait ones
  --help               Display this help message and exit
  --version            Display version information and exit

Example: curl -s $SCRIPT_URL | bash -s -- -i ~/Pictures/vacation -o ~/Pictures/landscape -w 1920 -h 1080

Dependencies:
  - sips (built into macOS)
  
Report issues: https://github.com/yourusername/portrait_to_landscape/issues
EOF
    exit 0
}

# Display version information
show_version() {
    echo "$SCRIPT_NAME v$VERSION"
    exit 0
}

# Check if running on macOS
check_system() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script requires macOS to run (needs the 'sips' command)."
        exit 1
    fi
    
    # Check if sips is available
    if ! command -v sips &> /dev/null; then
        echo "Error: 'sips' command not found. This script requires macOS."
        exit 1
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                INPUT_FOLDER="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FOLDER="$2"
                shift 2
                ;;
            -w|--width)
                TARGET_WIDTH="$2"
                shift 2
                ;;
            -h|--height)
                TARGET_HEIGHT="$2"
                shift 2
                ;;
            -r|--recursive)
                RECURSIVE=true
                shift
                ;;
            -c|--color)
                PAD_COLOR="$2"
                shift 2
                ;;
            -f|--force-all)
                FORCE_ALL=true
                shift
                ;;
            --help)
                show_help
                ;;
            --version)
                show_version
                ;;
            *)
                echo "Error: Unknown option: $1"
                echo "Try '$0 --help' for more information."
                exit 1
                ;;
        esac
    done
}

# Function to process a single image
process_image() {
    local img="$1"
    local output_subdir="$2"
    
    # Skip if not a regular file
    [ -f "$img" ] || return
    
    # Check if file is an image (based on extension)
    if [[ ! "$img" =~ \.(jpg|jpeg|png|JPG|JPEG|PNG)$ ]]; then
        return
    fi
    
    # Get the filename without path
    filename=$(basename "$img")
    
    # Create output subdirectory if needed
    if [ ! -z "$output_subdir" ]; then
        mkdir -p "$OUTPUT_FOLDER/$output_subdir"
        output_path="$OUTPUT_FOLDER/$output_subdir/$filename"
    else
        output_path="$OUTPUT_FOLDER/$filename"
    fi
    
    # Skip if output file already exists (don't overwrite)
    if [ -f "$output_path" ]; then
        echo "Skipping existing file: $output_path"
        return
    fi
    
    # Get image dimensions
    dimensions=$(sips -g pixelHeight -g pixelWidth "$img" 2>/dev/null | grep -E 'pixel(Height|Width)')
    
    # Check if sips command succeeded
    if [ $? -ne 0 ]; then
        echo "Error processing file: $img"
        return
    fi
    
    height=$(echo "$dimensions" | grep pixelHeight | awk '{print $2}')
    width=$(echo "$dimensions" | grep pixelWidth | awk '{print $2}')
    
    # Check if image is portrait (height > width) or if force-all is enabled
    if [ "$FORCE_ALL" = true ] || [ "$height" -gt "$width" ]; then
        echo "Converting image: $img -> $output_path"
        sips -p "$TARGET_HEIGHT" "$TARGET_WIDTH" --padColor "$PAD_COLOR" "$img" --out "$output_path" >/dev/null 2>&1
        
        # Check if conversion was successful
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert $img"
        fi
    else
        echo "Skipping non-portrait image: $img"
    fi
}

# Function to find and process images
process_folder() {
    local folder="$1"
    local rel_path="$2"
    
    # Process images in current folder
    for img in "$folder"/*; do
        # Skip if not a regular file or directory
        [ -e "$img" ] || continue
        
        if [ -f "$img" ]; then
            process_image "$img" "$rel_path"
        elif [ -d "$img" ] && [ "$RECURSIVE" = true ]; then
            # Process subdirectory recursively
            subdir=$(basename "$img")
            new_rel_path="$rel_path/$subdir"
            if [ -z "$rel_path" ]; then
                new_rel_path="$subdir"
            fi
            process_folder "$img" "$new_rel_path"
        fi
    done
}

# Display a fancy banner
show_banner() {
    echo "┌───────────────────────────────────────────────┐"
    echo "│ Portrait to Landscape Converter v$VERSION     │"
    echo "│ Convert portrait images to landscape with     │"
    echo "│ black bars using macOS built-in tools         │"
    echo "└───────────────────────────────────────────────┘"
    echo
}

# Main function
main() {
    show_banner
    check_system
    parse_args "$@"
    
    # Check if input folder exists
    if [ ! -d "$INPUT_FOLDER" ]; then
        echo "Error: Input directory '$INPUT_FOLDER' does not exist."
        exit 1
    fi
    
    # Create output folder if it doesn't exist
    mkdir -p "$OUTPUT_FOLDER"
    
    # Start processing
    echo "Starting image conversion..."
    echo "Input folder: $INPUT_FOLDER"
    echo "Output folder: $OUTPUT_FOLDER"
    echo "Target dimensions: ${TARGET_WIDTH}x${TARGET_HEIGHT}"
    echo "Padding color: $PAD_COLOR"
    echo "Recursive mode: $RECURSIVE"
    echo "Process all images: $FORCE_ALL"
    echo
    
    # Process the input folder
    process_folder "$INPUT_FOLDER" ""
    
    echo
    echo "✅ Processing complete!"
    echo "📁 Converted images saved to: $OUTPUT_FOLDER"
}

# Run the script
main "$@"
