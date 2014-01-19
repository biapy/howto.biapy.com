<?php
/**
 * Universal autoloader.
 *
 * @see http://www.croes.org/gerald/blog/la-strategie-strategy-en-php/93/
 */

class ExtensionFilterIteratorDecorator extends FilterIterator {
  private $_ext;
  public function accept (){
    if (substr ($this->current (), -1 * strlen ($this->_ext)) === $this->_ext){
      return is_readable ($this->current ());
    }
    return false;
  }
  public function setExtension ($pExt){
    $this->_ext = $pExt;
  }
}

interface IClassHunter {
  public function find ($pFileName);
}

class ClassHunterForPHP5_3 implements IClassHunter {
  public function find ($pFileName){
    $toReturn = array ();
    $tokens = token_get_all (file_get_contents ($pFileName, false));

    $currentNamespace = '';
    $namespaceHunt = false;
    $validatedNamespaceHunt = false;
    $classHunt = false;
    $whitespaceCount = 0;
    foreach ($tokens as $token){
      if (is_array ($token)){
        if ($token[0] === T_INTERFACE || $token[0] === T_CLASS){
          $classHunt = true;
          continue;
        }elseif ($token[0] === T_NAMESPACE){
          $namespaceHunt = true;
          continue;
        }

        if ($classHunt && $token[0] === T_STRING){
          $toReturn[(strlen ($currentNamespace) > 0 ? $currentNamespace.'\\' : '').$token[1]] = $pFileName;
          $classHunt = false;
        }elseif ($namespaceHunt && $validatedNamespaceHunt && ($token[0] === T_STRING || $token[0] === T_NS_SEPARATOR)){
          $currentNamespace .= $token[1];
        }elseif ($namespaceHunt && !$validatedNamespaceHunt && $token[0] === T_WHITESPACE){
          $currentNamespace = '';
          $validatedNamespaceHunt = true;
        }elseif ($namespaceHunt && !$validatedNamespaceHunt && $token[0] !== T_WHITESPACE){
          $namespaceHunt = false;
        }
      }else{
        if ($token === ';' || $token === '{'){
          //le seul cas ou cela permet de valider un namespace est la déclaration d'un namespace par défaut namespace{}
          if ($namespaceHunt && !$validatedNamespaceHunt && $token === '{'){
            $currentNamespace = '';
          }
          $classHunt = false;
          $namespaceHunt = false;
          $validatedNamespaceHunt = false;
        }
      }
    }
    return $toReturn;
  }
}

class ClassHunterForPHP5_2 implements IClassHunter {
  public function find ($pFileName){
    $toReturn = array ();
    $tokens = token_get_all (file_get_contents ($pFileName, false));
    $tokens = array_filter ($tokens, 'is_array');

    $classHunt = false;
    foreach ($tokens as $token){
      if ($token[0] === T_INTERFACE || $token[0] === T_CLASS){
        $classHunt = true;
        continue;
      }

      if ($classHunt && $token[0] === T_STRING){
        $toReturn[$token[1]] = $pFileName;
        $classHunt = false;
      }
    }
    return $toReturn;
  }
}

class DirectoriesAutoloaderException extends Exception {}

class DirectoriesAutoloader {
  private $_classHunterStrategy;

  //--- Singleton
  private function __construct (){}
  private static $_instance = false;
  public static function instance ($pTmpPath){
    if(self::$_instance === false){
      self::$_instance = new DirectoriesAutoloader();
      self::$_instance->setCachePath ($pTmpPath);
      self::$_instance->_classHunterStrategy = ClassHunterFactory::create (PHP_VERSION);
    }
    return self::$_instance;
  }
  //--- /Singleton

  public function register (){
    spl_autoload_register (array ($this, 'autoload'));
  }

  //--- Cache
  private $_cachePath;
  public function setCachePath ($pTmp){
    if (!is_writable ($pTmp)){
      throw new DirectoriesAutoloaderException('Cannot write in given CachePath ['.$pTmp.']');
    }
    $this->_cachePath = $pTmp;
  }
  //--- /Cache

  //--- Autoload
  public function autoload ($pClassName){
    //On regarde si on connais la classe
    if ($this->_loadClass ($pClassName)){
      return true;
    }

    //Si on a le droit de tenter la regénération du fichier d'autoload, on retente l'histoire
    if ($this->_canRegenerate){
      $this->_canRegenerate = false;//pour éviter que l'on
      $this->_includesAll ();
      $this->_saveInCache ();
      return $this->autoload ($pClassName);
    }
    //on a vraiment rien trouvé.
    return false;
  }
  private $_canRegenerate = true;
  //--- /Autoload

  /**
   * Recherche de toutes les classes dans les répertoires donnés
   */
  private function _includesAll (){
    //Inclusion de toute les classes connues
    foreach ($this->_directories as $directory=>$recursive){
      $directories = new AppendIterator ();

      //On ajoute tous les chemins à parcourir
      if ($recursive){
        $directories->append (new RecursiveIteratorIterator (new RecursiveDirectoryIterator ($directory)));
      }else{
        $directories->append (new DirectoryIterator ($directory));
      }

      //On va filtrer les fichiers php depuis les répertoires trouvés.
      $files = new ExtensionFilterIteratorDecorator ($directories);
      $files->setExtension ('.php');

      foreach ($files as $fileName){
        $classes = $this->_classHunterStrategy->find ((string) $fileName);
        foreach ($classes as $className=>$fileName){
          $this->_classes[strtolower ($className)] = $fileName;
        }
      }
    }
  }

  private $_classes = array ();
  private function _saveIncache (){
    $toSave = '<?php $classes = '.var_export ($this->_classes, true).'; ?>';
    if (file_put_contents ($this->_cachePath.'directoriesautoloader.cache.php', $toSave) === false){
      throw new DirectoriesAutoloaderException ('Cannot write cache file '.$this->_cachePath.'directoriesautoloader.cache.php');
    }
  }

  /**
   * Tente de charger une classe
   */
  private function _loadClass ($pClassName){
    if(class_exists(str_replace('\\', ':', $pClassName), false)){
      return true;
    }

    $className = strtolower ($pClassName);
    if (count ($this->_classes) === 0){
      if (is_readable ($this->_cachePath.'directoriesautoloader.cache.php')){
        require ($this->_cachePath.'directoriesautoloader.cache.php');
        if(isset($classes))
        {
          $this->_classes = $classes;
        }
      }
    }
    if (isset ($this->_classes[$className])){
      require_once ($this->_classes[$className]);
      return true;
    }
    return false;
  }

  /**
   * Ajoute un répertoire a la liste de ceux à autoloader
   */
  public function addDirectory ($pDirectory, $pRecursive = true){
    if (! is_readable ($pDirectory)){
      throw new DirectoriesAutoloaderException('Cannot read from ['.$pDirectory.']');
    }
    $this->_directories[$pDirectory] = $pRecursive ? true : false;
    return $this;
  }
  private $_directories = array ();
}

class ClassHunterFactory {
  public static function create ($version){
    if (($result = version_compare ($version, '5.3.0')) >= 0){
      return new ClassHunterForPHP5_3 ();
    }
    return new ClassHunterForPHP5_2 ();
  }
}
