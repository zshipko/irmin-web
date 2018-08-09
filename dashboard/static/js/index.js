function updateMaster() {
    ir.master().then((data) => {
        app.master = data;
        app.$forceUpdate();
    });
}

var errorTimeout = null;

var app = new Vue({
    el: '#app',
    data: {
        master: {},
        get: {},
        set: {},
        clone: {},
        list: {},
        push: {},
        pull: {},
        revert: {},
        block: '',
        error: null,
        items: [
            "get",
            "list",
            "set",
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
                app.list.items = x;
                app.list.key = '';
                app.$forceUpdate();
            }, app.Error);
        },
        Clone: (event) => {
            ir.clone(app.clone.uri).then((x) => {
                app.clone.uri = '';
                updateMaster();
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
                updateMaster();
            }, app.Error)
        },
        Set: (event) => {
            ir.set(app.set.key, app.set.value).then((x) => {
                app.set.key = '';
                app.set.value = '';
                updateMaster();
            }, app.Error)
        },
        Revert: (event) => {
            ir.revert(app.revert.hash).then((x) => {
                app.revert.hash = '';
                updateMaster();
            }, app.Error)
        }
    }
});

updateMaster();
