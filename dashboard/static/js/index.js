var irmin = ir;
ir = ir.master();

function updateBranch() {
    ir.info().then((data) => {
        app.branch = data;
        app.$forceUpdate();
    });
}

var errorTimeout = null;

var app = new Vue({
    el: '#app',
    data: {
        branch: {},
        get: {},
        set: {},
        remove: {},
        clone: {},
        list: {},
        push: {},
        pull: {},
        revert: {},
        switchBranch: {},
        block: '',
        error: null,
        items: [
            "branch",
            "get",
            "list",
            "set",
            "remove",
            "push",
            "clone",
            "pull",
            "revert"
        ]
    },
    methods: {
        Error: (msg) => {
            app.error = msg;
            app.$forceUpdate();
            if (errorTimeout) clearTimeout(errorTimeout);
            errorTimeout = setTimeout(() => {
                app.error = null;
                app.$forceUpdate();
            }, 3500);
        },
        SwitchBranch: (event) => {
            ir = app.switchBranch.name === "master" ? irmin.master() : irmin.branch(app.switchBranch.name);
            updateBranch();
        },
        Show: (key) => {
            app.block = 'get';
            ir.get(key).then((x) => {
                app.get.value = x;
                app.get.key = '';
                app.$forceUpdate();
            }, app.Error);
        },
        Get: (event) => {
            app.Show(app.get.key);
        },
        List: (event) => {
            ir.list(app.list.key).then((x) => {
                var arr = [];
                for (var k in x) {
                    var s;
                    if (x[k] === null) {
                        s = "DIR " + k;
                    } else {
                        s = "FILE " + k;
                    }
                    arr.push(s);
                }
                app.list.items = arr;
                app.list.key = '';
                app.$forceUpdate();
            }, app.Error);
        },
        Clone: (event) => {
            ir.clone(app.clone.uri).then((x) => {
                app.clone.uri = '';
                updateBranch();
            }, app.Error)
        },
        Push: (event) => {
            ir.push(app.push.uri).then((x) => {
                app.push.uri = '';
            }, app.Error)
        },
        Pull: (event) => {
            ir.pull(app.pull.uri).then((x) => {
                app.pull.uri = '';
                updateBranch();
            }, app.Error)
        },
        Set: (event) => {
            ir.set(app.set.key, app.set.value).then((x) => {
                app.set.key = '';
                app.set.value = '';
                updateBranch();
            }, app.Error)
        },
        Remove: (event) => {
            ir.remove(app.remove.key).then((x) => {
                app.remove.key = '';
                updateBranch();
            }, app.Error)
        },
        Revert: (event) => {
            ir.revert(app.revert.hash).then((x) => {
                app.revert.hash = '';
                updateBranch();
            }, app.Error)
        }
    }
});

updateBranch();
