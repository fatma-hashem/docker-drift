#!/bin/bash

# Docker Drift Detector: File + Package Drift

CONTAINER=$1

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




#######################################
        # FILESYSTEM DRIFT #
#######################################
echo " Filesystem Drift:"
echo "(A = Added, C = Changed, D = Deleted)"
docker diff "$CONTAINER" || echo " Could not check filesystem drift."
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

