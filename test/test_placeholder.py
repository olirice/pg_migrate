from sqlalchemy import text
from sqlalchemy.orm import Session


def test_true(sess: Session) -> None:
    assert True


def test_select_1(sess: Session) -> None:
    (one,) = sess.execute(text("select 1")).first()
    assert one == 1


def test_select_migrations_revision(sess: Session) -> None:
    rows = sess.execute(text("select * from migrations.revision")).all()

    assert len(rows) == 1


def test_ddl_ops_are_tracked(sess: Session) -> None:
    stmt = "create view test_view as select 1;"
    sess.execute(text(stmt))

    rows = sess.execute(text("select * from migrations.revision")).all()
    assert len(rows) == 2

    assert rows[1][1] == stmt


def test_select_migrations_revision_isolation(sess: Session) -> None:
    rows = sess.execute(text("select * from migrations.revision")).all()

    assert len(rows) == 1
