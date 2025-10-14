# OmniBLE
Omnipod Bluetooth PumpManager For Loop

## Status
This repository contains code to provide iOS control of a DASH pump. Originally written for Loop. It is also in use with Trio and iAPS.

## For more information
Please join loop zulipchat at https://loop.zulipchat.com/

## For test workaround for InPlay pods

This experimental branch has a new "Pod Keep Alive" option at the bottom of the "Omnipod DASH" screen.

### pod-keep-alive branch

The `pod-keep-alive` branch has updates to assist users who have both an iPhone 16 and DASH pods with a InPlay BLE (Atlas) board. No action is taken automatically unless both these cases are detected to be true.

It was tested for LoopWorkspace and Trio.

The concept is by choosing one of the Pod Keep Alive choices, the app sends a getStatus to the pod before the 3 minute disconnect happens. Therefore, so long as you and the pod stay close to the phone, the pod will be connected for a bolus (either manual or automatic) or temp basal or command to modify scheduled basal rates.

The selection for Pod Keep Alive is found at the bottom of the Pod settings screen.

The default value is Disabled.

There are 4 choices for Pod Keep Alive:

1. Disabled (default)
2. When Open
3. Silent Tune
4. RileyLink

#### Disabled

When Pod Keep Alive is disabled, the code behavior is unchanged from the nominal OmniBLE code.

If your app has Pod Keep Alive set to disabled and you have an iPhone 16 and the pod you just paired is an InPlay pod, the configuration automatically switches to When Open. It will remain at the When Open selection until you change it manually.

All three criteria must be true or no automatic change to the setting takes place:

* iPhone 16
* pair a new pod that is InPlay BLE (Atlas)
* Pod Keep Alive is Disabled

Note that during the time from pair to insert, the app keeps the screen open and unlocked unless you manually lock it.

This means you can take all the time you need between pair/prime and insert. As long as you don't manually lock the phone or move it out of range of the pod, the pod stays connected until you insert the cannula.

Once the pod is inserted, the phone auto-lock timing is restored to the value the user has selected.

#### When Open

When the app is open, it will send a getStatus to the pod 2:40 (mm:ss) after the last pod message was exchanged. This means the pod does not disconnect from BLE and remains available to the phone.

This is true as long as the phone and pod are in-range while the app is open with phone unlocked.

> If the pod moves out of Bluetooth range, the pod disconnects. With iPhone 16 it might take several seconds to minutes before the app reconnects to the pod once it is back in range. This can cause disruptions until the reconnect happens.

### Silent Tune

A silent tune is played in the background which keeps the app alive even when the phone is locked. This will increase the battery usage on the phone.

While Silent Tune is selected, the app will send a getStatus to the pod 2:40 (mm:ss) after the last pod message was exchanged. This means the pod does not disconnect from BLE and remains available for commands from the app so long as the phone and pod stay within Bluetooth range.

> If the pod moves out of Bluetooth range, the pod disconnects. With iPhone 16 it might take several seconds to minutes before the app reconnects to the pod once it is back in range. This can cause disruptions until the reconnect happens.

### RileyLink

For those who have a RileyLink (OrangeLink, EmaLink, etc), you can use that instead of the Silent Tune but you must keep the link with the phone.

While RileyLink is selected, the app is triggered by the RileyLink one minute heartbeat. The app will send a getStatus to the pod 2:00 (mm:ss) after the last pod message was exchanged. This means the pod does not disconnect from BLE and remains available for commands from the app so long as the phone and pod stay within Bluetooth range.

> If the pod moves out of Bluetooth range, the pod disconnects. With iPhone 16 it might take several seconds to minutes before the app reconnects to the pod once it is back in range. This can cause disruptions until the reconnect happens.

> If the phone moves out of RileyLink range, then the app is not triggered by the RileyLink heartbeat and the pod disconnects from BLE at the 3 minute cadence. With iPhone 16 it might take several seconds to minutes before the app reconnects to the pod once it is back in range. This can cause disruptions until the reconnect happens.
