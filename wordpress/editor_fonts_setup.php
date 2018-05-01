<?php
/**
 * Add custom web fonts to Wordpress editor and well known page builders.
 *
 * Shamelessly extrated from "Use Any Font" Wordpress plug-in.
 * @see https://fr.wordpress.org/plugins/use-any-font/
 *
 * To generate Web font CSS for any TTF file, use Font Squirrel:
 * @see https://www.fontsquirrel.com/tools/webfont-generator
 */

/**
 * Definitions of custom fonts added to the site.
 */
$THEME_FUNCTION_PREFIX_custom_fonts = array(
  /**
    For a font added to the theme with this CSS:

      @font-face {
          font-family: 'ExmouthRegular';
          src: url('exmouth_-webfont.eot');
          src: url('exmouth_-webfont.eot?#iefix') format('embedded-opentype'),
               url('exmouth_-webfont.woff') format('woff'),
               url('exmouth_-webfont.ttf') format('truetype'),
               url('exmouth_-webfont.svg#ExmouthRegular') format('svg');
          font-weight: normal;
          font-style: normal;
      }

   * The font declaration would be: 
   ** Font name in Wordpress interface             ** 'Exmouth Regular' => array(
   ** Font name as defined by CSS                  **   'name' => 'ExmouthRegular',
   ** Fallback fonts used when font is not present **   'fallbackFonts' => '"Helvetica Neue", Helvetica, Arial, sans-serif',
   ** Base font weight (400 for 'normal')          **   'weight' => '400',
   ** Font type (serif or sans-serif)              **   'type' => 'serif',
   ** Font supported charsets (at minima 'latin')  **   'charsets' => 'cyrillic,greek,latin' ),
  */
  'Exmouth Regular' => array(
    'name' => 'ExmouthRegular',
    'fallbackFonts' => '"Helvetica Neue", Helvetica, Arial, sans-serif',
    'weight' => '400',
    'type' => 'serif',
    'charsets' => 'cyrillic,greek,latin'
  ),
);



/**
 * Add the custom fonts to Tiny MCE, the default Wordpress editor.
 */
function THEME_FUNCTION_PREFIX_mce_before_init( $init_array ) {
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = '';

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts .= sprintf('%s=%s, %s;', $fontUiName ,$fontData['name'], $fontData['fallbackFonts']);
    }
  }

  $init_array['font_formats'] = $themeFonts . ';' . $init_array['font_formats'];
  // $init_array['font_formats'] = $theme_advanced_fonts.'Andale Mono=Andale Mono, Times;Arial=Arial, Helvetica, sans-serif;Arial Black=Arial Black, Avant Garde;Book Antiqua=Book Antiqua, Palatino;Comic Sans MS=Comic Sans MS, sans-serif;Courier New=Courier New, Courier;Georgia=Georgia, Palatino;Helvetica=Helvetica;Impact=Impact, Chicago;Symbol=Symbol;Tahoma=Tahoma, Arial, Helvetica, sans-serif;Terminal=Terminal, Monaco;Times New Roman=Times New Roman, Times;Trebuchet MS=Trebuchet MS, Geneva;Verdana=Verdana, Geneva;Webdings=Webdings;Wingdings=Wingdings';

  return $init_array;
} // THEME_FUNCTION_PREFIX_mce_before_init()

add_filter('tiny_mce_before_init', 'THEME_FUNCTION_PREFIX_mce_before_init' );



/**
 * Add font size select and font select control to Tiny MCE interface.
 */
function THEME_FUNCTION_PREFIX_mce_fonts_buttons( $options ) {
  array_unshift( $options, 'fontsizeselect');
  array_unshift( $options, 'fontselect');
  return $options;
} // THEME_FUNCTION_PREFIX_mce_fonts_buttons()

add_filter('mce_buttons_2', 'THEME_FUNCTION_PREFIX_mce_fonts_buttons');



/**
 * Add the custom font to Divi customizer and builder.
 *
 * @see https://www.elegantthemes.com/plugins/divi-builder/DIVI
 */
function THEME_FUNCTION_PREFIX_send_fonts_divi_list($fonts) {
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts[$fontData['name']] = array(
        'styles' => $fontData['weight'],
        'character_set' => $fontData['charsets'],
        'type' => $fontData['type']
      );
    }
  }

  return array_merge($themeFonts,$fonts);
} // THEME_FUNCTION_PREFIX_send_fonts_divi_list()

add_filter('et_websafe_fonts', 'THEME_FUNCTION_PREFIX_send_fonts_divi_list',10,2);



/**
 * Add the custom font to Site Origin builder.
 * @see https://fr.wordpress.org/plugins/siteorigin-panels/
 */
function THEME_FUNCTION_PREFIX_send_fonts_siteorigin_list($fonts) {
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts[$fontUiName] = sprintf('"%s", %s', $fontData['name'], $fontData['fallbackFonts']);
    }
  }

  return array_merge($themeFonts,$fonts);
} // THEME_FUNCTION_PREFIX_send_fonts_siteorigin_list()

add_filter('siteorigin_widgets_font_families', 'THEME_FUNCTION_PREFIX_send_fonts_siteorigin_list',10,2);



/**
 * Add the custom font to Redux Framework
 *
 * @see https://fr.wordpress.org/plugins/redux-framework/
 */
function THEME_FUNCTION_PREFIX_send_fonts_redux_list( $custom_fonts ) {
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array('Current Theme' => array());

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts['Current Theme'][$fontUiName] = sprintf('"%s", %s', $fontData['name'], $fontData['fallbackFonts']);
    }
  }

  return $themeFonts;
} // THEME_FUNCTION_PREFIX_send_fonts_redux_list()

if (class_exists('Redux')) {
  global $opt_name;
  add_filter('redux/'.$opt_name.'/field/typography/custom_fonts', 'THEME_FUNCTION_PREFIX_send_fonts_redux_list' );
}



/**
 * Add the custom font to X Theme
 *
 * @see https://theme.co/x/
 */
function THEME_FUNCTION_PREFIX_send_fonts_x_theme_list($fonts){
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts[$fontUiName] = array(
        'source'  => 'Current Theme',
        'family'  => $fontData['name'],
        'stack'   => sprintf('"%s", %s', $fontData['name'], $fontData['fallbackFonts']),
        'weights' => array( sprintf('%d', $fontData['weight']) )
      );
    }
  }

  return array_merge($themeFonts,$fonts);
} // THEME_FUNCTION_PREFIX_send_fonts_x_theme_list()

add_filter('x_fonts_data', 'THEME_FUNCTION_PREFIX_send_fonts_x_theme_list',10,2);



/**
 * Add the custom font to Elementor page builder
 *
 * @see https://wordpress.org/plugins/elementor/
 */
function THEME_FUNCTION_PREFIX_send_fonts_elementor_list( $controls_registry ) {
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts[$fontData['name']] = 'system';
    }
  }

  $fonts = $controls_registry->get_control( 'font' )->get_settings( 'options' );
  $new_fonts = array_merge($themeFonts, $fonts );
  $controls_registry->get_control( 'font' )->set_settings( 'options', $new_fonts );
} // THEME_FUNCTION_PREFIX_send_fonts_elementor_list()

add_action( 'elementor/controls/controls_registered', 'THEME_FUNCTION_PREFIX_send_fonts_elementor_list', 10, 1 );



/**
 * Add the custom font to Beaver Builder
 *
 * @see https://wordpress.org/plugins/beaver-builder-lite-version/
 */
function THEME_FUNCTION_PREFIX_send_fonts_beaver_builder_list($fonts){
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {
      $themeFonts[$fontData['name']] = array(
                      'fallback'  => $fontData['fallbackFonts'],
                      'weights'  => array( sprintf('%d', $fontData['weight']) )
                    );
    }
  }

  return array_merge($themeFonts,$fonts);
} // THEME_FUNCTION_PREFIX_send_fonts_beaver_builder_list()

add_filter('fl_builder_font_families_system', 'THEME_FUNCTION_PREFIX_send_fonts_beaver_builder_list',10,2);



/**
 * Add the custom font to Beaver Builder
 *
 * @see https://wordpress.org/plugins/themify-builder-lite/
 */
function THEME_FUNCTION_PREFIX_send_fonts_themify_builder_list($fonts){
  global $THEME_FUNCTION_PREFIX_custom_fonts;

  $themeFonts = array();

  if ($THEME_FUNCTION_PREFIX_custom_fonts) {
    foreach ( $THEME_FUNCTION_PREFIX_custom_fonts as $fontUiName => $fontData ) {

      $themeFonts[] = array(
        'name' => $fontUiName,
        'value' => sprintf('"%s", %s', $fontData['name'], $fontData['fallbackFonts'])
      );

    }
  }

  return array_merge($themeFonts,$fonts);
} // THEME_FUNCTION_PREFIX_send_fonts_themify_builder_list()

add_filter('themify_get_web_safe_font_list', 'THEME_FUNCTION_PREFIX_send_fonts_themify_builder_list',10,2);
