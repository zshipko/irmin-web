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
var query;

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
        if (this.path){
            return this.path.join('/');
        } else {
            return null;
        }
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
                response.text().then((x) => {
                    try {
                        resolve(JSON.parse(x).data)
                    } catch (err) {
                        reject(x)
                    }
                });
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
    }

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

    // Merge branches
    merge(into, from){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.merge,
                variables: {
                    into: into,
                    from: from,
                }
            }).then((x) => {
                resolve(x.merge)
            }, reject);
        })
    }

    // Push to a remote repository
    push(remote, branch=null){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.push,
                variables: {
                    remote: remote,
                    branch: branch,
                }
            }).then((x) => {
                resolve(x.push)
            }, reject);
        })
    }

    // Pull from a remote repository
    pull(remote, branch=null){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.pull,
                variables: {
                    remote: remote,
                    branch: branch,
                }
            }).then((x) => {
                resolve(x.pull)
            }, reject)
        })
    }

    // Restore Irmin to a previous state
    revert(commit, branch=null){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.revert,
                variables: {
                    commit: commit,
                    branch: branch,
                }
            }).then((x) => {
                resolve(x.revert.hash === commit)
            }, reject)
        })
    }

    // Clone from a remote repository
    clone(remote, branch=null){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.clone,
                variables: {
                    remote: remote,
                    branch: branch,
                }
            }).then((x) => {
                resolve(x.clone)
            }, reject)
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

    // Returns information about any branch
    branch(name){
        return new Promise((resolve, reject) => {
            this.execute({
                body: query.branch,
                variables: {
                    branch: name
                }
            }).then((x) => {
                resolve(x.branch)
            }, reject)
        });
    }

    list(key, branch=null){
        key = makeKey(key);
        return new Promise((resolve, reject) => {
            this.execute({
                body: branch == null ? query.listMaster : query.list,
                variables: {
                    key: key.string(),
                    branch: branch,
                }
            }).then((x) => {
                resolve((branch == null ? x.master : x.branch).head.node.get.tree)
            }, reject)
        })
    }

}

query = {
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

merge:
`
mutation Merge($into: String, $from: String!) {
    merge(into: $into, from: $from, info: null) {
        hash
    }
}
`,

push:
`
mutation Push($branch: String, $remote: String!) {
    push(branch: $branch, remote: $remote)
}
`,

pull:
`
mutation Pull($branch: String, $remote: String!) {
    pull(branch: $branch, remote: $remote, info: null) {
        hash
    }
}
`,

clone:
`
mutation Clone($branch: String, $remote: String!) {
    clone(branch: $branch, remote: $remote) {
        hash
    }
}
`,

revert:
`
mutation Revert($branch: String, $commit: String!) {
    revert(branch: $branch, commit: $commit) {
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
            parents {
                hash
            }
        }
    }
}
`,

branch:
`
query GetBranch($branch: String!) {
    branch(name: $branch) {
        name,
        head {
            hash,
            info {
                message,
                author,
                date
            }
            parents {
                hash
            }
        }
    }
}
`,

list:
`
query List($branch: String!, $key: String!) {
    branch(name: $branch) {
        head {
            node {
                get(key: $key) {
                    tree {
                        key,
                        value
                    }
                }
            }
        }
    }
}
`,

listMaster:
`
query ListMaster($key: String!) {
    master {
        head {
            node {
                get(key: $key) {
                    tree {
                        key,
                        value
                    }
                }
            }
        }
    }
}
`

};

