<?php
/**
 * Memcache & MySQL PHP Session Handler
 * 
 * @author Jakub Matějka <jakub@keboola.com>
 * @see http://pureform.wordpress.com/2009/04/08/memcache-mysql-php-session-handler/
 *
 * @author Pierre-Yves Landuré <pierre-yves.landure@biapy.fr>
 * @see http://howto.biapy.com/fr/debian-gnu-linux/serveurs/php/gerer-les-sessions-php-avec-memcached-et-mysql
 */

if(! interface_exists('SessionHandlerInterface'))
{
  interface SessionHandlerInterface {
    public function close();
    public function destroy($session_id);
    public function gc($maxlifetime);
    public function open($save_path, $name);
    public function read($session_id);
    public function write($session_id, $session_data);
  }
}

require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . 'memcached_mysql_sessionhandler_config.class.php');
class Memcached_MySQL_SessionHandler
    extends Memcached_MySQL_SessionHandler_Config
    implements SessionHandlerInterface
{

  const EXPIRATION_PREFIX = 'db-';

  /**
   * @var int
   */
  public $lifeTime;

  /**
   * @var Memcached
   */
  public $memcached;

  /**
   * @var MySQLi
   */
  public $mysqli;

  /**
   * @var string
   */
  public $initSessionData;

  /**
   * interval for session expiration update in the DB
   * @var int
   */
  protected $_refreshTime = 300; //5 minutes



  /**
   * constructor of the handler - initialises Memcached object
   *
   * @return bool
   */
  public function __construct()
  {
    // this ensures to write down and close the session when destroying the
    // handler object
    ini_set('session.save_handler', 'user');
    register_shutdown_function("session_write_close");

    $this->lifeTime = intval(ini_get("session.gc_maxlifetime"));
    $this->initSessionData = null;

    session_set_save_handler(
        array($this, "open"),
        array($this, "close"),
        array($this, "read"),
        array($this, "write"),
        array($this, "destroy"),
        array($this, "gc"));

    return true;
  } // __construct()



  /**
   * Init MySQLi connection.
   */
  protected function initMysqli()
  {
    if($this->mysqli instanceOf mysqli)
    {
      return false;
    }

    $this->mysqli = new mysqli(self::MYSQL_HOST, self::MYSQL_USER,
                              self::MYSQL_PASSWORD, self::MYSQL_DB);
    if($this->mysqli->connect_error)
    {
      die(sprintf('Connect Error (%s) %s',
          $this->mysqli->connect_errno,
          $this->mysqli->connect_error));
    }
  } // initMysqli()



  /**
   * Init memcached connection.
   */
  protected function initMemcached()
  {
    if($this->memcached instanceOf Memcached)
    {
      return false;
    }

    $this->memcached = new Memcached(self::MEMCACHED_ID);

    if(!$this->memcached->getServerList())
    {
      // This code block will only execute if we are setting up a new
      // EG(persistent_list) entry
      $this->memcached->setOption(Memcached::OPT_RECV_TIMEOUT, 1000);
      $this->memcached->setOption(Memcached::OPT_SEND_TIMEOUT, 3000);
      $this->memcached->setOption(Memcached::OPT_TCP_NODELAY, true);
      $this->memcached->setOption(Memcached::OPT_PREFIX_KEY,
                                        self::FIELD_PREFIX);
      $memcached_servers = explode(',', self::MEMCACHED_SERVERS);
      array_walk($memcached_servers,
          create_function('&$value', '$value = explode(":", $value);'));
      $this->memcached->addServers($memcached_servers);
    }

    return true;
  } // initMemcached()



  /**
   * opening of the session - mandatory arguments won't be needed
   * we'll get the session id and load session data, it the session exists
   *
   * @param string $savePath
   * @param string $sessionName
   * @return bool
   */
  public function open($savePath, $sessionName)
  {
    $this->initMemcached();
    $this->initMysqli();

    $session_id = session_id();
    if ($session_id !== "") {
      $this->initSessionData = $this->read($session_id);
    }

    return true;
  } // open()



  /**
   * closing the session
   *
   * @return bool
   */
  public function close()
  {
    $this->lifeTime = null;
    $this->initSessionData = null;

    unset($this->memcached);
    if($this->mysqli instanceOf mysqli)
    {
      $this->mysqli->close();
    }
    unset($this->mysqli);

    return true;
  } // close()



  /**
   * reading of the session data
   * if the data couldn't be found in the Memcache, we try to load it from the
   * DB we have to update the time of data expiration in the db using
   * _updateDbExpiration() the life time in Memcache is updated automatically
   * by write operation
   *
   * @param string $session_id
   * @return string
   */
  public function read($session_id)
  {
    $now = time();
    $data = $this->memcached->get($session_id);
    if($data === false)
    {
      $stmt = $this->mysqli->prepare(sprintf('SELECT %1$ssession_data FROM %2$sphp_session
          WHERE %1$ssession_id=?',
          self::FIELD_PREFIX, self::TABLE_PREFIX));
      $stmt->bind_param("s", $session_id);
      $stmt->execute();
      $stmt->bind_result($data);
      if($stmt->fetch())
      {
        $stmt->free_result();
        $this->_updateDbExpiration($session_id, $now);
      }
      else
      {
        // record not in the db
        $stmt->free_result();
        $data = '';
      }
      $stmt->close();
      unset($stmt);
    }
    else
    {
      // time of the expiration in the Memcache
      $expiration = $this->memcached->get(self::EXPIRATION_PREFIX.$session_id);
      if($expiration) {
        // if we didn't write into the db for at least
        // $this->_refreshTime (5 minutes), we need to refresh the expiration
        // time in the db
        if(($now - $this->_refreshTime) > ($expiration - $this->lifeTime)) {
          $this->_updateDbExpiration($session_id, $now);
        }
      }
      else
      {
        $this->_updateDbExpiration($session_id);
      }
    }

    $this->memcached->set($session_id, $data, $this->lifeTime);

    return $data ? $data : '';
  } // read()



  /**
   * update of the expiration time of the db record
   *
   * @param string $session_id
   * @param int $now UNIX timestamp
   */
  protected function _updateDbExpiration($session_id, $now=null)
  {
    if(!$now) {
      $now = time();
    }
    $expiration = $this->lifeTime + $now;

    $stmt = $this->mysqli->prepare(sprintf('UPDATE %2$sphp_session
                  SET %1$ssession_expiration=?
                  WHERE %1$ssession_id=?',
                  self::FIELD_PREFIX, self::TABLE_PREFIX));

    $stmt->bind_param("is", $expiration, $session_id);
    $stmt->execute();
    $stmt->close();

    // we store the time of the new expiration into the Memcache
    $this->memcached->set(self::EXPIRATION_PREFIX.$session_id, $expiration,
                          $this->lifeTime);
  } // _updateDbExpiration()



  /**
   * cache write - this is called when the script is about to finish,
   * or when session_write_close() is called
   * data are written only when something has changed
   *
   * @param string $session_id
   * @param string $data
   * @return bool
   */
  public function write($session_id, $data)
  {
    $now = time();
    $expiration = $this->lifeTime + $now;

    // we store time of the db record expiration in the Memcache
    $result = $this->memcached->set($session_id, $data, $this->lifeTime);

    if ($this->initSessionData !== $data) {
     $stmt = $this->mysqli->prepare(sprintf('INSERT INTO
              %2$sphp_session(%1$ssession_id, %1$ssession_expiration, %1$ssession_data)
              VALUES(?, ?, ?) ON DUPLICATE KEY UPDATE
              %1$ssession_expiration = ?, %1$ssession_data = ?',
              self::FIELD_PREFIX, self::TABLE_PREFIX));
      $stmt->bind_param("sisss", $session_id, $expiration, $data, $expiration, $data);
      $result = $stmt->execute();
      $stmt->close();

      $this->memcached->set(self::EXPIRATION_PREFIX.$session_id, $expiration,
                            $this->lifeTime);
    }
    return $result;
  } // write()



  /**
   * destroy of the session
   *
   * @param string $session_id
   * @return bool
   */
  public function destroy($session_id)
  {
    $this->memcached->delete($session_id);
    $this->memcached->delete(self::EXPIRATION_PREFIX.$session_id);
    $stmt = $this->mysqli->prepare(sprintf('DELETE FROM %2$sphp_session
                    WHERE %1$ssession_id=?',
                    self::FIELD_PREFIX, self::TABLE_PREFIX));
    $stmt->bind_param("s", $session_id);
    $stmt->execute();
    $stmt->close();

    return true;
  } // destroy()



  /**
   * called by the garbage collector
   *
   * @param int $maxlifetime
   * @return bool
   */
  public function gc($maxlifetime)
  {
    $stmt = $this->mysqli->prepare(sprintf('SELECT %1$ssession_id FROM %2$sphp_session
            WHERE %1$ssession_expiration<?',
            self::FIELD_PREFIX, self::TABLE_PREFIX));
    $stmt->bind_param("i", time());
    $stmt->execute();
    $result = $stmt->get_result();
    $session_ids = $result->fetch_all();
    $result->free();
    $stmt->close();

    foreach($session_ids as $session_id)
    {
      $this->destroy($session_id[0]);
    }

    return true;
  } // gc()
}

// Initialize custom session management.
new Memcached_MySQL_SessionHandler();

