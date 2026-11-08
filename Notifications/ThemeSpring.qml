import QtQuick
import "../Theme"

// SpringAnimation tuned with the theme's spring settings.
SpringAnimation {
    spring: Theme.springStiffness
    damping: Theme.springDamping
    mass: Theme.springMass
    epsilon: Theme.springEpsilon
}
