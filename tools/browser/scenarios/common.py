"""Focus and scroll synchronization through read-only diagnostics."""
import json

def focus(s, identity):
    for _ in range(len(s.state()['controls']) + 2):
        if s.state()['focused'] == identity:
            s.wait("window.umbralState.focused === " + json.dumps(identity) + " && window.umbralState.controls[" + json.dumps(identity) + "].fully_visible", timeout=5000)
            s.check(s.state()['controls'][identity]['fully_visible'], 'Focused scroll target is fully visible: ' + identity)
            return
        s.key('Tab')
    raise AssertionError('Could not reach focus target: ' + identity)

