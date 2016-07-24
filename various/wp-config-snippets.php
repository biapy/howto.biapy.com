// in some setups HTTP_X_FORWARDED_PROTO might contain 
// a comma-separated list e.g. http,https
// so check for https existence
if (isset( $_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)
       $_SERVER['HTTPS']='on';

if ( isset($_SERVER['HTTP_X_FORWARDED_FOR']) && !empty($_SERVER['HTTP_X_FORWARDED_FOR']) )
{
  $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
  $_SERVER['REMOTE_ADDR'] = trim($ips[0]);
}
elseif ( isset($_SERVER['HTTP_X_REAL_IP']) && !empty($_SERVER['HTTP_X_REAL_IP']) )
{
  $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_REAL_IP'];
}
elseif ( isset($_SERVER['HTTP_CLIENT_IP']) && !empty($_SERVER['HTTP_CLIENT_IP']) )
{
  $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_CLIENT_IP'];
}

// Enable WP_DEBUG mode
// define( 'WP_DEBUG', true );

// Enable Debug logging to the /wp-content/debug.log file
// define( 'WP_DEBUG_LOG', true );

// Disable display of errors and warnings 
// define( 'WP_DEBUG_DISPLAY', false );
// @ini_set( 'display_errors', 0 );

// Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
// define( 'SCRIPT_DEBUG', true );

