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
