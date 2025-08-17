#!/bin/bash

# Docker Drift Detector: File + Package Drift

CONTAINER=$1
REPORT_FILE="drift-report.html"

if [ -z "$CONTAINER" ]; then
  echo "Follow this format:  $0 <container_name_or_id>"
  exit 2
fi

# check if container exists (by ID or Name)
if ! docker ps -a --format '{{.ID}} {{.Names}}' | grep -qE "(${CONTAINER}$|^${CONTAINER})"; then
  echo "Error: Container '$CONTAINER' not found."
  exit 2
fi

echo "Scanning container: $CONTAINER"
echo ""

# Start HTML report
echo "<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<title>Docker Drift Report - $CONTAINER</title>
<style>
body { font-family: Arial, sans-serif; max-width: 900px; margin: auto; padding: 20px; }
h1 { color: #333; }
pre { background: #f4f4f4; padding: 10px; border-radius: 5px; overflow-x: auto; }
.added { color: green; }
.removed { color: red; }
.changed { color: orange; }
</style>
</head>
<body>
<h1>Docker Drift Report for $CONTAINER</h1>" > $REPORT_FILE

#######################################
        # FILESYSTEM DRIFT #
#######################################
echo " Filesystem Drift:"
echo "(A = Added, C = Changed, D = Deleted)"

FS_DIFF=$(docker diff "$CONTAINER" || echo " Could not check filesystem drift.")
echo "$FS_DIFF"
# Add to HTML
echo "<h2>Filesystem Drift</h2><pre>" >> $REPORT_FILE
echo "$FS_DIFF" | sed -E "s/^A/<span class='added'>A/; s/^C/<span class='changed'>C/; s/^D/<span class='removed'>D/" >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE
echo ""


#######################################
        # PACKAGE DRIFT #
#######################################
echo " Package Drift:"

# get base image of container
IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER")

if [ -z "$IMAGE" ]; then
  echo "Could not determine base image."
  exit 1
fi

# run "dpkg -l" (Debian/Ubuntu) or "rpm -qa" (RHEL/CentOS) in both
CONTAINER_PKGS=$(docker exec "$CONTAINER" sh -c "command -v dpkg >/dev/null && dpkg -l | awk '/^ii/ {print \$2, \$3}' || rpm -qa" 2>/dev/null)
IMAGE_PKGS=$(docker run --rm "$IMAGE" sh -c "command -v dpkg >/dev/null && dpkg -l | awk '/^ii/ {print \$2, \$3}' || rpm -qa" 2>/dev/null)

if [ -z "$CONTAINER_PKGS" ] || [ -z "$IMAGE_PKGS" ]; then
  echo "Could not retrieve package lists."
  exit 1
fi

# compare package lists
DIFF_OUTPUT=$(diff <(echo "$IMAGE_PKGS" | sort) <(echo "$CONTAINER_PKGS" | sort))

echo " Differences between container and its image:"
echo "$DIFF_OUTPUT"

# Add package drift to HTML
echo "<h2>Package Drift</h2><pre>" >> $REPORT_FILE
echo "$DIFF_OUTPUT" | sed -E "s/^> /<span class='added'>Added: /; s/^< /<span class='removed'>Removed: /" >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE

######################################
           # SUMMARY #
######################################

ADDED=$(echo "$DIFF_OUTPUT" | grep '^>' | wc -l)
REMOVED=$(echo "$DIFF_OUTPUT" | grep '^<' | wc -l)

echo ""
echo "Package Drift Summary:"
echo "Packages added to container: $ADDED"
echo "Packages removed from container: $REMOVED"

# Optional: track changed packages (same name, different version)
CHANGED=$(comm -12 <(echo "$IMAGE_PKGS" | awk '{print $1}' | sort) \
                   <(echo "$CONTAINER_PKGS" | awk '{print $1}' | sort) \
           | wc -l)
# echo "Packages changed: $CHANGED"

# Add summary to HTML
echo "<h2>Package Drift Summary</h2>
<p>Packages added to container: <span class='added'>$ADDED</span></p>
<p>Packages removed from container: <span class='removed'>$REMOVED</span></p>
</body></html>" >> $REPORT_FILE

echo "HTML report generated: $REPORT_FILE"

