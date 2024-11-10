# MotionEyeAudio Enhanced

## Overview
MotionEyeAudio Enhanced is a fork of the original MotionEyeAudio project designed to add audio recording to your MotionEye NVR setup. This enhanced version includes support for multiple cameras, improved audio quality, better synchronization between audio and video, and updated code for compatibility with Python 3.

## Features
- **Multi-Camera Support**: Seamlessly handles multiple cameras simultaneously, ideal for larger setups.
- **Audio-Video Synchronization**: Adjust the delay in motioneye-audio.sh `[line 55 : "[1:a]adelay=11000|11000[aud]"]` to better synchronize audio with video. The default delay is set to 11 seconds but can be modified as needed.
- **Audio Quality Settings**: Adjust FFmpeg parameters in motioneye-audio.sh for custom audio bitrate, sample rate, or volume settings `[line 39 : "volume=1.5"]`.
- **Error Handling**: Enhanced error handling ensures critical operations like audio capture and file merging are properly validated.
- **Python 3 Compatibility**: Updated to support Python 3 for modern systems and environments.
- **PID Management**: Improved process management for better stability.

## Installation
1. Download the `motioneye-audio.sh` script from the repository.
2. Copy the script to the appropriate directory:
   - **Docker**: Copy the script to `/etc/motioneye/` on the host machine.
   - **MotionEyeOS**: Copy the script to `/data/etc/` on the host machine.
3. Make the script executable:

    ```bash
    chmod +x /etc/motioneye/motioneye-audio.sh
    ```

## Configuration

1. **Camera Settings**: In the camera settings under the `Video Device` section, add the following to `Extra Options`:

   - **Docker**:

     ```
     on_movie_start /etc/motioneye/motioneye-audio.sh start %t %f '%$'
     ```

   - **MotionEyeOS**:

     ```
     on_movie_start /data/etc/motioneye-audio.sh start %t %f '%$'
     ```

2. **File Storage Settings**: In the `File Storage` section, enable `Run A Command` and add the following command:

   - **Docker**:

     ```
     /etc/motioneye/motioneye-audio.sh stop %t %f '%$'
     ```

   - **MotionEyeOS**:

     ```
     /data/etc/motioneye-audio.sh stop %t %f '%$'
     ```

3. These configurations must be repeated for each camera you wish to add audio to.

## Script Usage

The `motioneye-audio.sh` script supports two operations: `start` and `stop`.

- **start**: Begins capturing audio from the camera's network stream and saves it as an AAC file.
- **stop**: Stops the audio capture, merges the audio with the video, and ensures proper synchronization.

### Example

```bash
# Start capturing audio
/etc/motioneye/motioneye-audio.sh start <motion_thread_id> <file_path> <camera_name>

# Stop audio capture and merge audio with video
/etc/motioneye/motioneye-audio.sh stop <motion_thread_id> <file_path> <camera_name>
