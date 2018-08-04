let ir = new Irmin("http://localhost:5089/graphql");

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
