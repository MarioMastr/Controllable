#include "../../Controller.hpp"
#include "../../ControllableManager.hpp"
#include "../../globals.hpp"

#define CommentType CommentTypeDummy
#import <GameController/GameController.h>
#import <CoreHaptics/CoreHaptics.h>

Controller g_controller;

// this is how GD on macOS handles enabling controller

bool AppController_isControllerConnected(void* param_1, SEL param_2) {
	return g_controller.m_connected;
}

$execute {
    if (!geode::hook::replaceObjcMethod("AppController", "isControllerConnected", (void*)AppController_isControllerConnected))
        geode::log::error("Failed to hook AppController::isControllerConnected");
}

Controller::Controller()
    : m_state({})
    , m_lastDirection(GamepadDirection::None)
    , m_lastGamepadButton(GamepadButton::None)
    , m_vibrationTime(0.f)
    , m_connected(false) {}

void Controller::update(float dt) {
    m_lastDirection = directionPressed();
    m_lastGamepadButton = gamepadButtonPressed();
    
    for (GCController *i in [GCController controllers]) {
        if (!m_connected) {
            // just connected controller
            m_connected = true;
            g_isUsingController = true;
        }

        GCControllerInputState *inputState = [[i input] capture];

        m_state.m_buttonA  = [[[inputState buttons][GCInputButtonA] pressedInput] isPressed];
        m_state.m_buttonB  = [[[inputState buttons][GCInputButtonB] pressedInput] isPressed];
        m_state.m_buttonX  = [[[inputState buttons][GCInputButtonX] pressedInput] isPressed];
        m_state.m_buttonY  = [[[inputState buttons][GCInputButtonY] pressedInput] isPressed];

        m_state.m_buttonUp = [[[inputState dpads][GCInputDirectionPad] up] isPressed];
        m_state.m_buttonDown = [[[inputState dpads][GCInputDirectionPad] down] isPressed];
        m_state.m_buttonLeft = [[[inputState dpads][GCInputDirectionPad] left] isPressed];
        m_state.m_buttonRight = [[[inputState dpads][GCInputDirectionPad] right] isPressed];

        m_state.m_joyLeft = [[[inputState dpads][GCInputLeftThumbstick] down] isPressed];
        m_state.m_joyRight = [[[inputState dpads][GCInputRightThumbstick] down] isPressed];

        m_state.m_joyLeftX = [[[inputState dpads][GCInputLeftThumbstick] xAxis] value];
        m_state.m_joyLeftY = [[[inputState dpads][GCInputLeftThumbstick] yAxis] value];

        m_state.m_joyRightX = [[[inputState dpads][GCInputRightThumbstick] xAxis] value];
        m_state.m_joyRightY = [[[inputState dpads][GCInputRightThumbstick] yAxis] value];

        m_state.m_buttonStart = [[[inputState buttons][GCInputButtonMenu] pressedInput] isPressed];
        m_state.m_buttonSelect = [[[inputState buttons][GCInputButtonOptions] pressedInput] isPressed];

        m_state.m_buttonL = [[[inputState buttons][GCInputLeftBumper] pressedInput] isPressed];
        m_state.m_buttonR = [[[inputState buttons][GCInputRightBumper] pressedInput] isPressed];

        m_state.m_buttonZL = [[[inputState buttons][GCInputLeftTrigger] pressedInput] isPressed];
        m_state.m_buttonZR = [[[inputState buttons][GCInputRightTrigger] pressedInput] isPressed];

        inputState = [[i input] nextInputState]; // allows inputs to be held
    }
}

GamepadDirection Controller::directionJustPressed() {
    if (m_lastDirection != directionPressed()) return directionPressed();
    return GamepadDirection::None;
}

GamepadDirection Controller::directionJustReleased() {
    if (m_lastDirection != directionPressed()) return m_lastDirection;
    return GamepadDirection::None;
}

GamepadButton Controller::gamepadButtonJustPressed() {
    if (m_lastGamepadButton != gamepadButtonPressed()) return gamepadButtonPressed();
    return GamepadButton::None;
}

GamepadButton Controller::gamepadButtonJustReleased() {
    if (m_lastGamepadButton != gamepadButtonPressed()) return m_lastGamepadButton;
    return GamepadButton::None;
}


GamepadDirection Controller::directionPressed() {
    // d-pad
    if (m_state.m_buttonUp) return GamepadDirection::Up;
    if (m_state.m_buttonDown) return GamepadDirection::Down;
    if (m_state.m_buttonLeft) return GamepadDirection::Left;
    if (m_state.m_buttonRight) return GamepadDirection::Right;

    // 0 to 1
    float deadzone = cl::Manager::get().m_controllerJoystickDeadzone;

    // joystick
    if (m_state.m_joyLeftY > deadzone) return GamepadDirection::JoyUp;
    if (m_state.m_joyLeftY < -deadzone) return GamepadDirection::JoyDown;
    if (m_state.m_joyLeftX < -deadzone) return GamepadDirection::JoyLeft;
    if (m_state.m_joyLeftX > deadzone) return GamepadDirection::JoyRight;

    if (m_state.m_joyRightY > deadzone) return GamepadDirection::SecondaryJoyUp;
    if (m_state.m_joyRightY < -deadzone) return GamepadDirection::SecondaryJoyDown;
    if (m_state.m_joyRightX < -deadzone) return GamepadDirection::SecondaryJoyLeft;
    if (m_state.m_joyRightX > deadzone) return GamepadDirection::SecondaryJoyRight;

    return GamepadDirection::None;
}

GamepadButton Controller::gamepadButtonPressed() {
    if (m_state.m_buttonA) return GamepadButton::A;
    if (m_state.m_buttonB) return GamepadButton::B;
    if (m_state.m_buttonX) return GamepadButton::X;
    if (m_state.m_buttonY) return GamepadButton::Y;
    if (m_state.m_buttonStart) return GamepadButton::Start;
    if (m_state.m_buttonSelect) return GamepadButton::Select;
    if (m_state.m_buttonL) return GamepadButton::L;
    if (m_state.m_buttonR) return GamepadButton::R;
    if (m_state.m_buttonZL) return GamepadButton::ZL;
    if (m_state.m_buttonZR) return GamepadButton::ZR;
    if (m_state.m_buttonUp) return GamepadButton::Up;
    if (m_state.m_buttonDown) return GamepadButton::Down;
    if (m_state.m_buttonLeft) return GamepadButton::Left;
    if (m_state.m_buttonRight) return GamepadButton::Right;
    if (m_state.m_joyLeft) return GamepadButton::JoyLeft;
    if (m_state.m_joyRight) return GamepadButton::JoyRight;

    return GamepadButton::None;
}

cocos2d::CCPoint Controller::getLeftJoystick() {
    return { m_state.m_joyLeftX, m_state.m_joyLeftY };
}

cocos2d::CCPoint Controller::getRightJoystick() {
    return { m_state.m_joyRightX, m_state.m_joyRightY };
}


void Controller::vibrate(float duration, float left, float right) {
    m_vibrationTime = duration;

    for (GCController *i in [GCController controllers]) {
        GCDeviceHaptics *hapticsHandler = [i haptics];

        if (hapticsHandler) {
            CHHapticEngine *hapticsEngine = [hapticsHandler createEngineWithLocality:GCHapticsLocalityDefault];

            NSError *initError;
            [hapticsEngine initAndReturnError:&initError];

            NSDictionary* hapticDict = @{
                CHHapticPatternKeyPattern: @[ 
                    @{ CHHapticPatternKeyEvent: @{
                        CHHapticPatternKeyEventType: CHHapticEventTypeHapticContinuous,
                        CHHapticPatternKeyTime: @(CHHapticTimeImmediate),
                        CHHapticPatternKeyEventDuration: @(duration) },
                    },
                ],
            };

            NSError* patternError;
            CHHapticPattern* pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&patternError];

            NSError* playerError;
            id<CHHapticPatternPlayer> player = [hapticsEngine createPlayerWithPattern:pattern error:&playerError];

            [hapticsEngine notifyWhenPlayersFinished:^CHHapticEngineFinishedAction(NSError * _Nullable error) {
                return CHHapticEngineFinishedActionStopEngine;
            }];
                
            [hapticsEngine startWithCompletionHandler:^(NSError* returnedError) {
                NSError* startError;
                [player startAtTime:0 error:&startError];
            }];
        }
    }
}