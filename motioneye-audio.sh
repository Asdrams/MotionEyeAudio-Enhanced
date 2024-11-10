#!/usr/bin/env bash

# Assign command-line arguments to descriptive variables for clarity
operation=$1            # The operation to perform, either 'start' or 'stop'
motion_thread_id=$2     # The thread ID from MotionEye, used to identify the specific camera
file_path=$3            # The path to the file where the audio will be saved or processed
camera_name=$4          # The name of the camera, which could be useful for future extensions

# Use a Python script to map the provided MotionEye thread ID to the corresponding camera ID
# This call invokes the motioneye.motionctl module to obtain the correct camera ID
camera_id=$(python3 -c "import motioneye.motionctl; print(motioneye.motionctl.motion_camera_id_to_camera_id(${motion_thread_id}))")

# Determine the directory where the script is located (base directory for configuration files)
motion_config_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
motion_camera_conf="${motion_config_dir}/camera-${camera_id}.conf"  # Path to the camera's specific configuration file

# Identify which network stream configuration to use; prioritize 'netcam_highres' if available, otherwise fall back to 'netcam_url'
netcam=$(grep -q 'netcam_highres' "${motion_camera_conf}" && echo 'netcam_highres' || echo 'netcam_url')

# Extract the file extension and the base filename from the provided file path for later use
extension="${file_path##*.}"  # Extract file extension (e.g., mp4, mkv, etc.)
filename=$(basename "${file_path}")  # Extract just the filename (without path)

# Define a temporary file for storing the process ID of the audio capturing process, which allows later termination
audio_pid_file="/tmp/motion-audio-${camera_id}-${filename}"

# Main control structure for 'start' or 'stop' operations
case ${operation} in
    start)
        # Extract the netcam credentials (if any) from the camera's configuration
        credentials=$(grep -oP 'netcam_userpass \K.+' "${motion_camera_conf}")
        
        # Retrieve the full network stream URL from the configuration, appending credentials if present
        stream=$(grep "${netcam}" "${motion_camera_conf}" | sed -e "s/^${netcam}[ \t]*//")
        full_stream="${stream//\/\//\/\/${credentials}@}"  # Insert credentials into the URL, if available

        # Use FFmpeg to capture the audio from the network stream and save it as an AAC file
        # The audio filter '-filter:a "volume=3.0"' adjusts the volume level. The current value of 3.0 is optimal for the purpose but can be adjusted
        ffmpeg -y -i "${full_stream}" -c:a aac -b:a 128k -ar 44100 -filter:a "volume=1.5" "${file_path}.aac" &
        
        # Record the process ID of the audio capture process so it can be stopped later
        echo $! > "${audio_pid_file}"
        ;;

    stop)
        # If the audio PID file exists, retrieve the stored process ID and stop the audio capture process
        if [ -f "${audio_pid_file}" ]; then
            pid=$(cat "${audio_pid_file}")
            kill "${pid}" && rm -f "${audio_pid_file}"  # Terminate the audio process and delete the PID file
        fi

        # Combine the video and audio files using FFmpeg, with a slight delay to synchronize them
        # The 'adelay=11000|11000[aud]' filter adds an 11-second delay to the audio to ensure it aligns with the video
        # The delay value is adjustable to suit different synchronization needs
        ffmpeg -i "${file_path}" -i "${file_path}.aac" -filter_complex "[1:a]adelay=11000|11000[aud]" -map 0:v -map "[aud]" -c:v copy -c:a aac -b:a 128k -ar 44100 "${file_path}.temp.${extension}"
        
        # If the FFmpeg command executes successfully, replace the original file with the newly merged file
        [ $? -eq 0 ] && mv -f "${file_path}.temp.${extension}" "${file_path}"
        
        # Clean up by removing the temporary audio file
        rm -f "${file_path}.aac"
        ;;

    *)
        # If an unrecognized operation is provided, terminate the script with an error code
        exit 1
        ;;
esac
