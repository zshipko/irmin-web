let ir = new Irmin("http://localhost:5089/graphql");

function updateMaster() {
    ir.master().then((data) => {
        app.master = data;
        app.$forceUpdate();
    });
}

var errorTimeout;

var app = new Vue({
    el: '#app',
    data: {
        master: {},
        get: {},
        set: {},
        clone: {},
        list: {},
        block: '',
        error: null,
        items: [
            "get",
            "list",
            "clone",
            "set",
        ]
    },
    methods: {
        Error: (msg) => {
            app.error = msg;
            if (errorTimeout) clearTimeout(errorTimeout);
            errorTimeout = setTimeout(() => {
                app.error = null;
                app.$forceUpdate();
            }, 3500);
        },
        Get: (event) => {
            ir.get(app.get.key).then((x) => {
                app.get.value = x;
                app.get.key = '';
            }, app.Error);
        },
        List: (event) => {
            var key = app.list.key;
            key = key == '/' || key == '' ? null : key;
            ir.list(key).then((x) => {
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
        Set: (event) => {
            ir.set(app.set.key, app.set.value).then((x) => {
                app.set.key = '';
                app.set.value = '';
                updateMaster();
            })
        }
    }
});

updateMaster();
