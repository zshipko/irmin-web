QUnit.test("BranchRef name", function(assert){
    assert.ok(ir.master().name == "master");
    assert.ok(ir.branch("testing").name == "testing");
});

QUnit.test("Get/set", function(assert){
    let done = assert.async();
    let master = ir.master();
    master.set("abc", "1234").then(res => {
        assert.ok(res.hash);
        master.get("abc").then(res => {
            assert.ok(res == "1234");
            done();
        });
    });
});

QUnit.test("Get/set aaa", function(assert){
    let done = assert.async();
    let aaa = ir.branch('aaa');
    aaa.set("abc", "1234").then(res => {
        assert.ok(res.hash);
        aaa.get("abc").then(res => {
            assert.ok(res == "1234");
            done();
        });
    });
});

QUnit.test("List", function(assert){
    let done = assert.async();
    let master = ir.master();
    master.list().then(res => {
        assert.ok(res["abc"] === "1234")
        done();
    }, err => {
        assert.ok(false);
        done();
    });
});

QUnit.test("Remove", function(assert){
    let done = assert.async();
    let master = ir.master();
    master.remove("abc").then(res => {
        assert.ok(res.hash);

        master.get("abc").then(res => {
            assert.ok(res == null);
            done();
        });
    });
});

QUnit.test("Master info", function(assert){
    let done = assert.async();
    let master = ir.master();
    master.info().then(res => {
        assert.ok(res.name == "master");
        assert.ok(res.head.hash);
        done();
    });
});

QUnit.test("Testing branch info", function(assert){
    let done = assert.async();
    let testing = ir.branch('testing');
    testing.info().then(res => {
        assert.ok(res.name == "testing");
        assert.ok(res.head === null);
        done();
    });
});

QUnit.test("Pull", function(assert){
    let done = assert.async();
    let master = ir.master();
    master.pull('git://github.com/zshipko/irmin-web').then(res => {
        master.get('README.md').then(res => {
            assert.ok(res != null);
            assert.ok(res.length > 0);
            assert.ok(res.startsWith('irmin-web'));
            done();
        });
    });
});

QUnit.test("Merge", function(assert){
    let done = assert.async();
    let aaa = ir.branch('aaa');
    aaa.merge('master').then(res => {
        aaa.get('README.md').then(res => {
            assert.ok(res != null);
            assert.ok(res.length > 0);
            assert.ok(res.startsWith('irmin-web'));
            done();
        });
    });
});

