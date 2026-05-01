<?php
$host = 'terraform-20260501055922493000000003.cr40amieu2yc.ap-northeast-1.rds.amazonaws.com';
$user = 'admin';
$pass = 'kazu-6187';
$db   = 'kazu_DB';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("接続失敗: " . $conn->connect_error);
}

// メモの保存
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['content'])) {
    $content = $conn->real_escape_string($_POST['content']);
    $conn->query("INSERT INTO memos (content) VALUES ('$content')");
}

// メモの取得
$result = $conn->query("SELECT * FROM memos ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Kazuメモアプリ</title>
</head>
<body>
  <h1>📝 Kazuメモアプリ</h1>

  <form method="POST">
    <input type="text" name="content" placeholder="メモを入力" size="40">
    <button type="submit">保存</button>
  </form>

  <hr>

  <h2>メモ一覧</h2>
  <?php while ($row = $result->fetch_assoc()): ?>
    <p><?= htmlspecialchars($row['content']) ?> <small>(<?= $row['created_at'] ?>)</small></p>
  <?php endwhile; ?>
</body>
</html>