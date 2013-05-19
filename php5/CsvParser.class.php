<?php
/**
 * CsvParser object.
 * This object is used to parse CSV files.
 *
 * The configuration array syntax is:
 *   array(
 *     'result_column_name' => array(
 *           'title' => 'CSV colum title',
 *           'type' => CsvParser::TYPE,
 *           'mandatory' => true,
 *           'force_presence' => true,
             'max_length' => 10,
             'filler' => '0',
 *         )
 *   )
 *
 * If 'force_presence' is true, a Exception is thrown if the column
 * is not present in the CSV file.
 *
 * If 'mandatory' is true, a Exception is thrown if the column
 * is not present in the CSV file, or if it has a empty value.
 *
 * 'max_length' and 'filler' allow to limit the value lenth and to fill
 * it to the 'max_length' if it is shorter.
 *
 * CsvParser::TYPE is to be choosen in:
 *   STRING, INTEGER, FLOAT, DATE, BOOLEAN
 * If not specified, it is considered as a STRING.
 *
 * @package    easyCreaDoc
 * @subpackage lib.tools
 * @author     Pierre-Yves Landuré <py.landure@dorigo.fr>
 * @version    SVN: $Id$
 */
class CsvParser
{

  /**
   *  The STRING column type.
   */
  const STRING = 'string';

  /**
   *  The INTEGER column type.
   */
  const INTEGER = 'integer';

  /**
   *  The FLOAT column type.
   */
  const FLOAT = 'float';

  /**
   *  The DATE column type.
   */
  const DATE = 'date';

  /**
   *  The BOOLEAN column type.
   */
  const BOOLEAN = 'boolean';

  /**
   * supported CSV separators.
   * 
   * @var array
   * @access protected
   */
  protected $separators;


  /**
   * Boolean True values strings.
   * 
   * @var array
   * @access protected
   */
  protected $true_values;

  /**
   * CSV parser configuration.
   * Tell CSV column title, type, and destination variable.
   * 
   * @var array
   * @access protected
   */
  protected $configuration;

  /**
   * This object constructor
   * 
   * @param array $configuration The CSV parser configuration.
   * @access public
   * @return void
   */
  public function __construct($configuration)
  {
    // Get the translation function
    if(class_exists('sfLoader'))
    {
      // Symfony 1.0 specifics.
      sfLoader::loadHelpers('I18N', sfContext::getInstance()->getModuleName());
    }

    $this->separators = array(';', ',');
    $this->true_values = array('1', 'TRUE', 'X', 'V', __('TRUE'));

    $this->setConfiguration($configuration);
  }



  /**
   * Manage calls to I18N functions.
   *
   * @param string $string The text to translate.
   * @param array $values Optionnal substitutions.
   * @access protected
   * @return string The translated text.
   */
  protected function __($string, $values = array())
  {
    if(function_exists('__'))
    {
      // Symfony 1.0 specifics.
      return __($string, $values);
    }

    foreach($values as $name => $value)
    {
      $string = str_replace($name, $value, $string);
    }

    return $string;
  } // __()



  /**
   * Set this CSV parser configuration.
   * 
   * @param array $configuration The CSV parser configuration.
   * @access public
   * @return void
   */
  public function setConfiguration($configuration)
  {
    foreach($configuration as $result_column => $infos)
    {
      if(is_string($infos))
      {
        $configuration[$result_column] = array(
                'title' => $infos,
                'mandatory' => false,
                'force_presence' => false,
                'type' => self::STRING,
                'max_length' => false,
                'filler' => false,
              );
      }
      elseif(is_array($infos))
      {
        if(!isset($infos['mandatory']))
        {
          $infos['mandatory'] = false;
        }

        if(!isset($infos['force_presence']))
        {
          $infos['force_presence'] = false;
        }

        if(!isset($infos['type']))
        {
          $infos['type'] = self::STRING;
        }

        if(!isset($infos['max_length']) || $infos['max_length'] < 0)
        {
          $infos['max_length'] = false;
        }

        if(!isset($infos['filler']) || $infos['filler'] == '')
        {
          $infos['filler'] = false;
        }

        if(!isset($infos['title']))
        {
          throw new Exception(__('Configuration is not valid: column title is missing.'));
        }

        $configuration[$result_column] = $infos;
      }
      else
      {
        throw new Exception(__('Configuration is not valid: result column must be a string or a array.'));
      }
    }

    $this->configuration = $configuration;
  }

  /**
   * Get this CSV parser configuration.
   * 
   * @access public
   * @return array This CSV parser configuration.
   */
  public function getConfiguration()
  {
    return $this->configuration;
  }



  /**
   * Parse a file
   * 
   * @param string $filename The file path.
   * @param string $type A optionnal MIME type.
   * @access public
   * @return array The CSV contents.
   * @see CsvParser::parseCsv()
   */
  public function parseFile($filename, $type = null)
  {
    if(!file_exists($filename))
    {
      return false;
    }

    if(is_null($type))
    {
      $type = MimeTypeTool::detectMimeType($filename);
    }

    $extension_for_type = MimeTypeTool::getExtensionByMimeType($type);
    switch($extension_for_type)
    {
      case 'xls':
        return $this->parseExcel($filename);
        break;

      case 'txt':
      case 'csv':
        return $this->parseCsv($filename);
        break;

      default:
        if($uploaded_file->getType() == 'application/x-ole-storage') // Test if file is a strange excel file.
        {
          return $this->parseExcel($filename);
        } // Test if file is a strange excel file.

        throw new Exception(__('File is neither a Excel or a CSV file.'));
    }

    return false;
  } // parseFile()



  /**
   * Parse a uploaded CSV
   * 
   * @param string $field The uploaded file field name.
   * @access public
   * @return array The CSV contents.
   * @see CsvParser::parseCsv()
   */
  public function parseUploadedCsv($field)
  {
    $uploaded_file = new UploadedFile($field);

    if($uploaded_file->hasFile())
    {
      $extension_for_type = MimeTypeTool::getExtensionByMimeType($uploaded_file->getType());
      switch($extension_for_type)
      {
        case 'xls':
          return $this->parseExcel($uploaded_file->getFilePath());
          break;

        case 'txt':
        case 'csv':
          return $this->parseCsv($uploaded_file->getFilePath());
          break;

        default:
          if($uploaded_file->getType() == 'application/x-ole-storage') // Test if file is a strange excel file.
          {
            return $this->parseExcel($uploaded_file->getFilePath());
          } // Test if file is a strange excel file.

          throw new Exception(__('Uploaded file is neither a Excel or a CSV file.'));
      }
    }

    return false;
  } // parseUploadedCsv()



  /**
   * Detect if the string is encoded in UTF-8.
   * 
   * @param string $string The tested string.
   * @access public
   * @return boolean True if the string is in UTF-8, false otherwhise.
   * @link http://www.php.net/manual/en/function.mb-detect-encoding.php#68607
   */
  public static function isUtf8($string)
  {
    return preg_match('%(?:'
      . '[\xC2-\xDF][\x80-\xBF]'                // non-overlong 2-byte
      . '|\xE0[\xA0-\xBF][\x80-\xBF]'           // excluding overlongs
      . '|[\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}'    // straight 3-byte
      . '|\xED[\x80-\x9F][\x80-\xBF]'           // excluding surrogates
      . '|\xF0[\x90-\xBF][\x80-\xBF]{2}'        // planes 1-3
      . '|[\xF1-\xF3][\x80-\xBF]{3}'            // planes 4-15
      . '|\xF4[\x80-\x8F][\x80-\xBF]{2}'        // plane 16
      . ')+%xs', $string);
  }



  /**
   * Get the CSV or XLS columns association with this CsvParser configured columns.
   * 
   * @param array $headers The first line of the file.
   * @access protected
   * @return array A array of columns associations.
   * @throw Exception if a mandatory column is missing.
   */
  protected function getColumnsAssociations($headers)
  {
    $columns = array();

    foreach($this->configuration as $result_column => $infos)
    {
      // We try to find the result column in the CSV file.
      foreach($headers as $index => $name)
      {
        // We encode in UTF-8
        if(! self::isUtf8($name)) // Test if value is in utf-8.
        {
          // If the value is not in utf-8, we try to encode it to utf-8.
          $name = utf8_encode($name);
        } // Test if value is in utf-8.

        if(trim(strtoupper($infos['title'])) == trim(strtoupper($name)))
        {
          $columns[$result_column] = $index;
          break;
        }
      }

      // We test if any mandatory column is missing.
      $is_mandatory = false;

      if(isset($infos['mandatory']))
      {
        $is_mandatory |= $infos['mandatory'];
      }

      if(isset($infos['force_presence']))
      {
        $is_mandatory |= $infos['force_presence'];
      }

      if($is_mandatory && !isset($columns[$result_column]))
      {
        throw new Exception(__('Column %column% is missing.', array('%column%' => $infos['title'])));
      }

    }

    if(count($columns) == 0) // Test if columns associations found.
    {
      throw new Exception(__('No corresponding column found.'));
    } // Test if columns associations found.

    return $columns;
  } // getColumnsAssociations()



  /**
   * Convert the value according to the source column type.
   * 
   * @param string $result_column The source result column 
   * @param mixed $value The source value.
   * @param integer $line_number The current line number.
   * @access protected
   * @return mixed The converted value.
   */
  protected function getColumnValue($result_column, $value, $line_number)
  {
    $value = trim($value);

    if($value == '')
    {
      $value = null;
    }

    if(isset($this->configuration[$result_column]['mandatory']))
    {
      if($this->configuration[$result_column]['mandatory'] && !$value)
      {
        throw new Exception(__("Column %column% is missing at line %line%.", array('%column%' => $this->configuration[$result_column]['title'], '%line%' => $line_number)));
      }
    }

    $type = self::STRING;
    if(isset($this->configuration[$result_column]['type']))
    {
      $type = $this->configuration[$result_column]['type'];
    }

    switch($type) // Value conversion switch.
    {
      case self::INTEGER:
        $value = intval($value);
        break;
      case self::FLOAT:
        $value = floatval($value);
        break;
      case self::DATE:
        if($value)
        {
          if(class_exists('sfI18N'))
          {
            // Symfony 1.0 specifics.
            list($d, $m, $y) = sfI18N::getDateForCulture($value, $user_culture);
            $value = "$y-$m-$d";
          }
        }
        else
        {
          $value = null;
        }
        break;
      case self::BOOLEAN:
        $value = in_array(strtoupper($value), $this->true_values);
        break;
      case self::STRING:
      default:

        // Max Length and filler
        if($this->configuration[$result_column]['max_length'])
        {
          if($this->configuration[$result_column]['filler'])
          {
            $value .= str_repeat($this->configuration[$result_column]['filler'],
                                 $this->configuration[$result_column]['max_length']);
          }
          $value = substr($value, 0, $this->configuration[$result_column]['max_length']);
        }

        // We encode in UTF-8
        if(! self::isUtf8($value)) // Test if value is in utf-8.
        {
          // If the value is not in utf-8, we try to encode it to utf-8.
          $value = utf8_encode($value);
        } // Test if value is in utf-8.
        
        break;
    } // Value conversion switch.

    return $value;
  } // getColumnValue()



  /**
   * Parse a XLS file
   * 
   * @param string $file The CSV file.
   * @access public
   * @return array The XLS contents.
   */
  public function parseExcel($file)
  {
    if(!file_exists($file))
    {
      return array();
    }

    $excel = new SpreadsheetExcelReader();
    $excel->setOutputEncoding('UTF-8');

    $excel->read($file);

    if(! isset($excel->sheets[0])) // Test if sheet found.
    {
      return array();
    } // Test if sheet found.

    if(! $excel->sheets[0]['numRows']) // Test if empty sheet.
    {
      return array();
    } // Test if empty sheet.

    // We fetch the first line.
    $headers = $excel->sheets[0]['cells'][1];

    $columns = $this->getColumnsAssociations($headers);

    $results = array();

    // We can now parse the CSV contents
    foreach($excel->sheets[0]['cells'] as $line_number => $xls_line) // For each xls file lines.
    {
      if($line_number > 1) // We ignore first line.
      {
        $line = array();
        foreach($columns as $result_column => $index)
        {
          $value = null;
          if(isset($xls_line[$index]))
          {
            $value = $this->getColumnValue($result_column, $xls_line[$index], $line_number);
          }

          $line[$result_column] = $value;
        }

        $results[] = $line;

        unset($xls_line, $line);
      } // We ignore first line.
    } // For each xls file lines.

    unset($excel);

    return $results;

  } // parseExcel()



  /**
   * Parse a CSV file
   * 
   * @param string $file The CSV file.
   * @access public
   * @return array The CSV contents.
   */
  public function parseCsv($file)
  {
    if(!file_exists($file))
    {
      return array();
    }

    $results = array();
    $file_separator = $this->separators[0];
    $user_culture = sfContext::getInstance()->getUser()->getCulture();

    // We open the CSV file:
    $file_handle = fopen($file, 'r');

    if($file_handle !== false) // Test if file opened correctly.
    {
      // We fetch the first line of the file.
      // We assume that the first line contains the CSV columns.
      $first_line = fgets($file_handle);
      if($first_line === false) // Test if we can get the first CSV line as text.
      {
        fclose($file_handle);
        return $results;
      } // Test if we can get the first CSV line as text.


      $current_separator_count = substr_count($first_line, $file_separator);

      // We try to detect the separator used.
      foreach($this->separators as $separator)
      {
        $separator_count = substr_count($first_line, $separator);
        if($separator_count > $current_separator_count)
        {
          $current_separator_count = $separator_count;
          $file_separator = $separator;
        }
      }

      // We get one more time the first line:
      rewind($file_handle);
      $csv_headers = fgetcsv($file_handle, null, $file_separator);

      if($csv_headers === false) // Test if we can get the first CSV line.
      {
        fclose($file_handle);
        return $results;
      } // Test if we can get the first CSV line.

      $columns = $this->getColumnsAssociations($csv_headers);

      // We can now parse the CSV contents
      $line_number = 2;
      while(($csv_line = fgetcsv($file_handle, null, $file_separator)) !== false)
      {
        $line = array();
        foreach($columns as $result_column => $index)
        {
          $value = null;
          if(isset($csv_line[$index]))
          {
            $value = $this->getColumnValue($result_column, $csv_line[$index], $line_number);
          }

          $line[$result_column] = $value;
        }

        $results[] = $line;

        $line_number += 1;
      }

      fclose($file_handle);
    } // Test if file opened correctly.

    return $results;
  } // parseCsv()

}

