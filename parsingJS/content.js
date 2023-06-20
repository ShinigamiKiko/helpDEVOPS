function checkForTriggers() {
  var triggers = [
    { text: "Текст триггера 1", sound: "badsiren.mp3" },
    { text: "Текст триггера 2", sound: "verybad.mp3" },
    { text: "Аккаунты", sound: "badsiren.mp3" }
  ];

  // Проверка текста в теле документа
  triggers.forEach(function(trigger) {
    var recordText = document.body.textContent;
    if (recordText.includes(trigger.text)) {
      chrome.runtime.sendMessage({ action: "playSound", sound: trigger.sound });
    }
  });

  // Проверка текста гиперссылок
  var links = Array.from(document.getElementsByTagName('a'));
  triggers.forEach(function(trigger) {
    links.forEach(function(link) {
      if (link.textContent.includes(trigger.text)) {
        chrome.runtime.sendMessage({ action: "playSound", sound: trigger.sound });
      }
    });
  });
}

checkForTriggers();