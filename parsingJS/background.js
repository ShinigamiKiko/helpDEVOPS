chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "playSound" && request.sound) {
    var audio = new Audio(chrome.runtime.getURL(request.sound));
    audio.play();
  }
});