(function () {
  try {
    const data = localStorage.getItem("profile_cache");
    if (!data) return;

    const profile = JSON.parse(data);

    const daysLeft = Number(profile.days_left);

    if (!isNaN(daysLeft) && daysLeft <= 0) {
      window.location.replace("/");
    }

  } catch (e) {
    console.error("Invalid profile_cache", e);
  }
})();
