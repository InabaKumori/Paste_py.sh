#!/bin/bash
# Get the current public IP address
CURRENT_IP=$(curl -s http://ifconfig.me)
# Directory to store the uploaded files
UPLOAD_DIRECTORY="$HOME/.paste_uploads"
# Create the upload directory if it doesn't exist
mkdir -p "$UPLOAD_DIRECTORY"
# Function to generate a unique filename
generate_filename() {
    echo "$(date +%Y%m%d%H%M%S)_$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
}
# Function to paste the file and generate the URL
paste_file() {
    local file_path="$1"
    local filename=$(generate_filename)
    local destination_path="$UPLOAD_DIRECTORY/$filename"
    # Copy the file to the upload directory
    cp "$file_path" "$destination_path"
    # Generate the URL for accessing the file
    local url="http://$LOCAL_IP:55554/$filename.html"
    echo "$url"
}
# Check if a file path is provided as an argument
if [ $# -eq 0 ]; then
    echo "Please provide the path to the file you want to paste."
    exit 1
fi
file_path="$1"
# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "File '$file_path' does not exist."
    exit 1
fi
# Get the local IP address
if [[ "$OSTYPE" == "darwin"* ]]; then
    LOCAL_IP=$(ipconfig getifaddr en0)
else
    LOCAL_IP=$(ifconfig | grep 'inet addr' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d':' -f2 | head -n 1)
fi
# Paste the file and get the URL
url=$(paste_file "$file_path")
echo "File pasted successfully. Access it at: $url"
# Print additional messages
echo "Access it at: http://$CURRENT_IP:55554/$(basename "$url")"
echo "Warning: You might be under a NAT. You may wish to access the page at: http://$LOCAL_IP:55554/$(basename "$url")"
# Create an HTML file for each pasted file
filename=$(basename "$url" .html)
html_file="$UPLOAD_DIRECTORY/$filename.html"
cat > "$html_file" <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Pasted File</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f0f0f0;
        }
        h1 {
            color: #333;
        }
        pre {
            background-color: #fff;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <h1>Pasted File</h1>
    <pre>$(cat "$UPLOAD_DIRECTORY/$filename")</pre>
</body>
</html>
EOL
# Start a simple HTTP server to serve the HTML pages
cd "$UPLOAD_DIRECTORY"
python -m http.server 55554 --bind $LOCAL_IP
