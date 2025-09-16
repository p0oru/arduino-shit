// Four-LED Binary Display (uses 4 green halves of bi-color LEDs)
// Assumes LED pairs on: {2,3}, {4,5}, {6,7}, {8,9}
// Displays 0–15 based on Serial input (decimal like "9" or binary like "1010").
// If input is out of range or invalid, flashes RED/GREEN randomly as an error effect.

const uint8_t LED_PAIRS[4][2] = {
  {2, 3}, // LED1 pair
  {4, 5}, // LED2 pair
  {6, 7}, // LED3 pair
  {8, 9}  // LED4 pair
};

// If green color appears as red, set this to true (swaps polarity on all LEDs)
bool invertGreenPolarity = false;

void setLedOff(uint8_t index) {
  digitalWrite(LED_PAIRS[index][0], LOW);
  digitalWrite(LED_PAIRS[index][1], LOW);
}

void setLedRed(uint8_t index, bool on) {
  const uint8_t pinA = LED_PAIRS[index][0];
  const uint8_t pinB = LED_PAIRS[index][1];
  if (!on) {
    digitalWrite(pinA, LOW);
    digitalWrite(pinB, LOW);
    return;
  }
  // Red is the opposite polarity of green
  if (invertGreenPolarity) {
    digitalWrite(pinA, HIGH);
    digitalWrite(pinB, LOW);
  } else {
    digitalWrite(pinA, LOW);
    digitalWrite(pinB, HIGH);
  }
}

void setLedGreen(uint8_t index, bool on) {
  const uint8_t pinA = LED_PAIRS[index][0];
  const uint8_t pinB = LED_PAIRS[index][1];
  if (!on) {
    digitalWrite(pinA, LOW);
    digitalWrite(pinB, LOW);
    return;
  }
  if (invertGreenPolarity) {
    digitalWrite(pinA, LOW);
    digitalWrite(pinB, HIGH);
  } else {
    digitalWrite(pinA, HIGH);
    digitalWrite(pinB, LOW);
  }
}

void displayValueOnLeds(uint8_t value) {
  for (uint8_t i = 0; i < 4; i++) {
    const bool bitOn = (value >> i) & 0x01; // LSB on LED1 → MSB on LED4
    setLedGreen(i, bitOn);
  }
}

void turnAllOff() {
  for (uint8_t i = 0; i < 4; i++) setLedOff(i);
}

void flashRandomError(uint8_t cycles = 20, uint16_t stepMs = 70) {
  for (uint8_t c = 0; c < cycles; c++) {
    for (uint8_t i = 0; i < 4; i++) {
      const bool chooseGreen = random(0, 2) == 0;
      if (chooseGreen) {
        setLedGreen(i, true);
      } else {
        setLedRed(i, true);
      }
    }
    delay(stepMs);
    for (uint8_t i = 0; i < 4; i++) setLedOff(i);
    delay(stepMs);
  }
  for (uint8_t i = 0; i < 4; i++) setLedOff(i);
}

bool isBinaryString(const String &s) {
  if (s.length() == 0 || s.length() > 4) return false;
  for (uint16_t i = 0; i < s.length(); i++) {
    if (s[i] != '0' && s[i] != '1') return false;
  }
  return true;
}

bool isDecimalString(const String &s) {
  if (s.length() == 0) return false;
  uint16_t start = 0;
  if (s[0] == '+' || s[0] == '-') {
    if (s.length() == 1) return false;
    start = 1;
  }
  for (uint16_t i = start; i < s.length(); i++) {
    if (s[i] < '0' || s[i] > '9') return false;
  }
  return true;
}

uint8_t parseBinaryToValue(const String &s) {
  uint8_t val = 0;
  for (uint16_t i = 0; i < s.length(); i++) {
    val = (val << 1) | (s[i] == '1');
  }
  return val & 0x0F;
}

void setup() {
  // Initialize pins
  for (uint8_t i = 0; i < 4; i++) {
    pinMode(LED_PAIRS[i][0], OUTPUT);
    pinMode(LED_PAIRS[i][1], OUTPUT);
    setLedOff(i);
  }

  Serial.begin(9600);
  randomSeed(analogRead(A0));
  Serial.println("Four-LED Binary Display");
  Serial.println("Type 0-15 (decimal) or binary like 1010.");
  Serial.println("Type 'invert' to flip colors, 'off' to clear, 'exit' to clear and stop.");

  // Start with 0000
  displayValueOnLeds(0);
}

void loop() {
  if (Serial.available()) {
    String s = Serial.readStringUntil('\n');
    s.trim();
    s.toLowerCase();
    if (s.length() == 0) return;

    if (s == "invert") {
      invertGreenPolarity = !invertGreenPolarity;
      Serial.print("invertGreenPolarity=");
      Serial.println(invertGreenPolarity ? "true" : "false");
      // Refresh last value (default to 0 after invert)
      displayValueOnLeds(0);
      return;
    }

    if (s == "off") {
      turnAllOff();
      Serial.println("All LEDs off.");
      return;
    }

    if (s == "exit") {
      turnAllOff();
      Serial.println("Exit requested. LEDs off.");
      delay(50);
      return; // sketch keeps running; host script will close serial
    }

    bool valid = false;
    uint8_t value = 0;

    if (isBinaryString(s)) {
      value = parseBinaryToValue(s);
      valid = true;
    } else if (isDecimalString(s)) {
      long v = s.toInt();
      if (v >= 0 && v <= 15) {
        value = static_cast<uint8_t>(v);
        valid = true;
      }
    }

    if (!valid) {
      Serial.println("Out of range/invalid. Flashing random colors...");
      flashRandomError();
      turnAllOff();
      return;
    }

    displayValueOnLeds(value);
    Serial.print("Shown value: ");
    Serial.println(value);
  }
}


