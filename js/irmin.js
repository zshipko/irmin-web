// irmin.js provides simple bindings to access irmin-graphql endpoints from the browser.

// `request` is a small wrapper around `fetch` for sending requests to
// remote servers
function request(url, body){
    return fetch(url, {
        method: 'POST',
        body: JSON.stringify(body),
        header: {
            "Content-Type": "application/json"
        }
    });
}

// The `query` object contains all of the pre-defined queries
let query = {
get:
`
query GetKey($branch: String!, $key: String!) {
    branch(name: $branch) {
        get(key: $key) {
            value
        }
    }
}
`,

set:
`
mutation SetKey($branch: String, $key: String!, $value: String!) {
    set(branch: $branch, key: $key, value: $value, info: null) {
        hash
    }
}
`,

remove:
`
mutation RemoveKey($branch: String, $key: String!) {
    remove(branch: $branch, key: $key, info: null) {
        hash
    }
}
`,

master:
`
query {
    master {
        name
        head {
            hash,
            info {
                message,
                author,
                date
            }
            parents
        }
    }
}
`,
};

// Used to store keys as an array of strings, this is meant to mirror
// the way keys are represented in Irmin
class Key {
    constructor(k) {
        if (typeof k === 'string'){
            this.path = k.split('/');
        } else {
            this.path = k
        }
    }

    string(){
        return this.path.join('/');
    }
}

// `makeKey` converts a value into a key, if needed
function makeKey(k) {
    if (k instanceof Key){
        return k;
    }

    return new Key(k);
}

// `Irmin` is the main client implementation
class Irmin {
    constructor(url){
        this.url = url;
    }

    // Execute a query, with the given variables and operation name
    execute({body, variables={}, operation=null}){
        let q = {
            query: body,
            operationName: operation,
            variables: variables,
        };

        return new Promise((resolve, reject) => {
            return request(this.url, q).then((response) => {
                response.json().then((j) => {
                    resolve(j.data)
                }, reject)
            }, reject);
        });
    }

    // Get a value from Irmin
    get(key, branch="master"){
        key = makeKey(key);
        return new Promise ((resolve, reject) => {
            this.execute({
                body: query.get,
                variables: {
                    key: key.string(),
                    branch: branch
                }
            }).then((x) => {
                resolve(x.branch.get)
            }, reject);
        })
    }

    // Store a value in Irmin
    set(key, value, branch=null){
        key = makeKey(key);
        return new Promise ((resolve, reject) => {
            this.execute({
                body: query.set,
                variables: {
                    key: key.string(),
                    value: value,
                    branch: branch
                }
            }).then((x) => {
                resolve(x.set)
            }, reject);
        })
    },

    // Remove a value
    remove(key, branch=null){
        key = makeKey(key);
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.remove,
                variables: {
                    key: key.string(),
                    branch: branch,
                }
            }).then((x) => {
                resolve(x.remove)
            }, reject);
        })
    }

    // Returns information about the master branch
    master(){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.master
            }).then((x) => {
                resolve(x.master)
            }, reject)
        });
    }
}
