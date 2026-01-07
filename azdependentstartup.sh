#!/bin/bash
# 1. Update and install Apache (httpd)
# Amazon Linux uses 'yum', and the web server is 'httpd'
yum update -y
yum install -y httpd unzip

# Note: Amazon Linux 2023 comes with AWS CLI v2 pre-installed.
# Amazon Linux 2 comes with v1. This block ensures v2 is installed on either.
if ! aws --version | grep "aws-cli/2"; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
fi

# Start and enable Apache (httpd)
systemctl start httpd
systemctl enable httpd

# 2. AWS Metadata Retrieval (IMDSv2 - Secure Token Method)
# This logic remains the same across Linux distros
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
METADATA_URL="http://169.254.169.254/latest/meta-data"
HEADER_FLAG="-H"
HEADER_VAL="X-aws-ec2-metadata-token: $TOKEN"

local_ipv4=$(curl "$HEADER_FLAG" "$HEADER_VAL" -s "${METADATA_URL}/local-ipv4")
full_zone=$(curl "$HEADER_FLAG" "$HEADER_VAL" -s "${METADATA_URL}/placement/availability-zone")
instance_id=$(curl "$HEADER_FLAG" "$HEADER_VAL" -s "${METADATA_URL}/instance-id")
instance_type=$(curl "$HEADER_FLAG" "$HEADER_VAL" -s "${METADATA_URL}/instance-type")

# 3. Logic for zone sensitivity (Video selection)
case "$full_zone" in
  *a)
    bg_image="https://i.imgur.com/MhKxc8e.jpeg"
    video_url="https://i.imgur.com/Ua78lXF.mp4"
    ;;
  *b)
    bg_image="https://i.imgur.com/gaaY0T2.jpeg"
    video_url="https://i.imgur.com/Xxzg2Nz.mp4"
    ;;
  *c)
    bg_image="https://i.imgur.com/vm3iG93.jpeg"
    video_url="https://i.imgur.com/A0cLa17.mp4"
    ;;
  *)
    bg_image="https://i.imgur.com/ADZbhBu.jpeg"
    video_url="https://i.imgur.com/rqT1z57.mp4"
    ;;
esac

# 4. Create the HTML page
# Note: Permission handling for 'tee' is slightly different if not root, 
# but User Data runs as root by default.
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>AWS Amazon Linux Demo</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Montserrat">
  <style>
    body,h1,h3 {font-family: "Montserrat", sans-serif}
    body, html {height: 100%}
    .bgimg {
      background-image: url('$bg_image');
      min-height: 100%;
      background-position: center;
      background-size: cover;
    }
    .w3-display-middle {
      background-color: rgba(0, 0, 0, 0.466);
      padding: 20px;
      border-radius: 10px;
    }
    .transparent-background {
      background-color: rgba(0, 0, 0, 0.575);
      padding: 20px;
      border-radius: 10px;
    }
  </style>
</head>
<body>
  <div class="bgimg w3-display-container w3-animate-opacity w3-text-white">
    <div class="w3-display-middle w3-center">
      <video width="360" height="540" style="border-radius:10px;" controls loop autoplay muted>
          <source src="$video_url" type="video/mp4">
          Your browser does not support the video tag.
      </video>
    </div>
    <div class="w3-display-bottomright w3-padding-small transparent-background outlined-text">
      <h1>Amazon Linux Instance Info</h1>
      <p><b>Instance ID:</b> $instance_id</p>
      <p><b>Instance Type:</b> $instance_type</p>
      <p><b>Private IP: </b> $local_ipv4</p>
      <p><b>Availability Zone: </b> $full_zone</p>
    </div>
  </div>
</body>
</html>
EOF
