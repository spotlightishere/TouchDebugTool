# TouchDebugTool
On 7th generation iPod nanos, a debug Bluetooth service is available for sending raw touchscreen events.

## Enabling
1. Plug in your iPod, and mount its volume.
2. Go to `iPod_Control/Device` within its volume. (Under macOS, you may need to use Finder's "Go to Folder", or to show hidden files.)
3. Enable options (feature flags) by creating an empty file called `_enable_options`.
4. Enable this service's option by creating another empty file named `_touch_debug_bt`.
