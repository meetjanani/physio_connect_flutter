const LAT_LONG_SEPRATOR = "@-@";
const DOCTOR_USER_ID_LIST = [3, 8, 65];

// flutter isDoctor function that check userId is coming from DOCTOR_USER_ID_LIST ?
bool isDoctorTypeUser(int userId) => DOCTOR_USER_ID_LIST.contains(userId);