<?php
$host = 'terraform-20260501055922493000000003.cr40amieu2yc.ap-northeast-1.rds.amazonaws.com';
$user = 'admin';
$pass = 'kazu-6187';
$db   = 'kazu_DB';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("接続失敗: " . $conn->connect_error);
}

echo "<h1>DB接続成功！</h1>";
echo "MySQLバージョン: " . $conn->server_info;
$conn->close();
?>