<?php

$mail_domain = str_replace('autoconfig.', '', $_SERVER['HTTP_HOST']);

$default_domain = $mail_domain;

$imap_server = 'imap.' . $default_domain;
$smtp_server = 'smtp.' . $default_domain;
$pop3_server = 'pop3.' . $default_domain;

$protocols = array(
    'imap/tls',
    'imaps',
    'pop3/tls',
    'pop3s',
    'smtps',
    'smtp/tls-587',
    'smtp/tls'
  );

header('Content-Type: text/xml');
echo '<?xml version="1.0" encoding="UTF-8"?>';
?>
<clientConfig version="1.1">
  <emailProvider id="<?php echo $mail_domain ?>">
    <domain><?php echo $mail_domain ?></domain>
    <displayName><?php echo $mail_domain ?> Mail</displayName>
    <displayShortName><?php echo $mail_domain ?></displayShortName>
<?php foreach($protocols as $protocol): ?>
  <?php switch($protocol):
      case 'imap/tls':
    ?>
    <incomingServer type="imap">
      <hostname><?php echo $imap_server ?></hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <?php
      break;
      case 'imaps':
    ?>
    <incomingServer type="imap">
      <hostname><?php echo $imap_server ?></hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <?php
      break;
      case 'pop3/tls':
    ?>
    <incomingServer type="pop3">
      <hostname><?php echo $pop3_server ?></hostname>
      <port>110</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <?php
      break;
      case 'pop3s':
    ?>
    <incomingServer type="pop3">
      <hostname><?php echo $pop3_server ?></hostname>
      <port>995</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <?php
      break;
      case 'smtp/tls-587':
    ?>
    <outgoingServer type="smtp">
      <hostname><?php echo $smtp_server ?></hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
    <?php
      break;
      case 'smtp/tls':
    ?>
    <outgoingServer type="smtp">
      <hostname><?php echo $smtp_server ?></hostname>
      <port>25</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
    <?php
      break;
      case 'smtps':
    ?>
    <outgoingServer type="smtp">
      <hostname><?php echo $smtp_server ?></hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
    <?php
      break;
    ?>
  <?php endswitch ?>
<?php endforeach ?>
  </emailProvider>
</clientConfig>
