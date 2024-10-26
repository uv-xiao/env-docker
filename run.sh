#!/bin/bash

# Default values
IMG_NAME="hw-env"
CONTAINER_NAME="hw_env"

# commands: pull, build, run
# options:
#   img_name (-i)
#   container_name (-c)
#   mount_info (-v)
# Parse command-line arguments
while [ $# -gt 0 ]; do
    case $1 in
        build|run)
            COMMAND=$1
            shift
            ;;
        -i|--img-name)
            IMG_NAME=$2
            shift 2
            ;;
        -c|--container-name)
            CONTAINER_NAME=$2
            shift 2
            ;;
        -v|--mount-info)
            MOUNT_INFO=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if a command was provided
if [ -z "$COMMAND" ]; then
    echo "Error: No command specified. Use 'build' or 'run'."
    exit 1
fi

# If MOUNT_INFO is provided, use `jq` to parse the json file it points to;
# turn the parsed json into a docker mount string
# for example, `{"/path/to/dir1": "/path/in/container1", "/path/to/dir2": "/path/in/container2"}` 
# will be turned into `-v /path/to/dir1:/path/in/container1 -v /path/to/dir2:/path/in/container2`
# use realpath to get the absolute path
if [ -n "$MOUNT_INFO" ]; then
  MOUNT_INFO=$(jq -r 'to_entries | map("-v $(realpath $(pwd)/\(.key)):\(.value)") | join(" ")' $MOUNT_INFO)
  MOUNT_INFO=$(eval echo $MOUNT_INFO)
fi



# echo the task to be executed
echo_task() {
  echo "COMMAND: $COMMAND"
  if [ -n "$IMG_NAME" ]; then
    echo "  IMG_NAME: $IMG_NAME"
  fi
  if [ -n "$CONTAINER_NAME" ]; then
    echo "  CONTAINER_NAME: $CONTAINER_NAME"
  fi
  if [ -n "$MOUNT_INFO" ]; then
    echo "  MOUNT_INFO: $MOUNT_INFO"
  fi
}

echo_task


execute_task() {
  # TODO: allow user to specify the base-image
  if [ "$COMMAND" = "pull" ]; then
    docker pull ubuntu:22.04
  fi

  if [ "$COMMAND" = "build" ]; then
    docker build -t $IMG_NAME .
  fi

  if [ "$COMMAND" = "run" ]; then
    docker run -itd --name $CONTAINER_NAME --network host $MOUNT_INFO $IMG_NAME /bin/bash
  fi
}

execute_task
