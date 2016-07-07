defmodule BitcoinHSMServerRESTTest do
  use ExUnit.Case, async: false

  @timeout 20000

  setup do
    host = Application.get_env(:bitcoin_hsm_server, :host, '127.0.0.1')
    port = Application.get_env(:bitcoin_hsm_server, :port, 7070)

    {:ok, conn_pid} = :gun.open(host, port)
    {:ok, proto} = :gun.await_up(conn_pid)

    on_exit fn ->
      :ok = :gun.shutdown(conn_pid)
    end

    {:ok, conn: conn_pid, proto: proto}
  end

  test "open connection", ctx do
    assert is_pid(ctx[:conn])
    assert ctx[:proto] == :http
  end

  @wif "5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF"
  test "import/wif", ctx do
    ref = post(ctx[:conn], "import/wif", %{wif: @wif})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    assert byte_size(epk) >= 48
  end

  @seed "000102030405060708090a0b0c0d0e0f"
  test "import/seed", ctx do
    ref = post(ctx[:conn], "import/seed", %{seed: @seed})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    assert byte_size(epk) >= 48
  end

  @public_key "0439a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c23cbe7ded0e7ce6a594896b8f62888fdbc5c8821305e2ea42bf01e37300116281"
  test "public_key", ctx do
    ref = post(ctx[:conn], "import/seed", %{seed: @seed})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    assert byte_size(epk) >= 48
    ref = post(ctx[:conn], "public_key", %{epk: epk})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"public_key" => public_key} = assert_data(ctx[:conn], ref)
    assert public_key == @public_key
  end

  @extended_public_key "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
  test "extended_public_key", ctx do
    ref = post(ctx[:conn], "import/seed", %{seed: @seed})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    assert byte_size(epk) >= 48
    ref = post(ctx[:conn], "extended_public_key", %{epk: epk})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"extended_public_key" => public_key} = assert_data(ctx[:conn], ref)
    assert public_key == @extended_public_key
  end

  @child_extended_public_key "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
  test "derive", ctx do
    ref = post(ctx[:conn], "import/seed", %{seed: @seed})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    ref = post(ctx[:conn], "derive", %{epk: epk, key_path: "m/0p/1"})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => child_epk} = assert_data(ctx[:conn], ref)
    ref = post(ctx[:conn], "extended_public_key", %{epk: child_epk})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"extended_public_key" => public_key} = assert_data(ctx[:conn], ref)
    assert public_key == @child_extended_public_key
  end

  @hash "b7405daebb63964ba8ebd35933a56538fafd131d9fda4fc463d926f6f736cf57"
  @signature "3045022100d51f8e7647d378c22e99ccdeb7166dd9b0539fdfffc4bb32fffcfcaa0d5b82630220564aebdbda5e3ae2f7d88f5aa3cb878b6d4077e951a895eb404b47d709a5b5ee"

  test "sign", ctx do
    ref = post(ctx[:conn], "import/seed", %{seed: @seed})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"epk" => epk} = assert_data(ctx[:conn], ref)
    ref = post(ctx[:conn], "sign", %{epk: epk, hash: @hash})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"signature" => @signature} == assert_data(ctx[:conn], ref)
  end

  test "verify", ctx do
    ref = post(ctx[:conn], "verify", %{public_key: @public_key, hash: @hash, signature: @signature})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"valid" => true} = assert_data(ctx[:conn], ref)
  end

  test "random", ctx do
    ref = post(ctx[:conn], "random", %{bytes: 42})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"random" => random} = assert_data(ctx[:conn], ref)
    assert byte_size(Base.decode16!(random, case: :lower)) == 42
    ref = post(ctx[:conn], "random", %{bytes: 11})
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"random" => random2} = assert_data(ctx[:conn], ref)
    assert byte_size(Base.decode16!(random2, case: :lower)) == 11
    assert random != random2
  end

  def post(conn_pid, path, body) do
    {:ok, body} = JSX.encode(body)
    :gun.post(conn_pid, url(path), [
      {"content-type", 'application/json'}
    ], body)
  end

  defp assert_response(conn, ref) do
    assert_receive {:gun_response, conn_resp, ref_resp, :nofin, status, _headers}, @timeout
    assert conn == conn_resp
    assert ref == ref_resp
    status
  end

  defp assert_data(conn, ref) do
    assert_receive {:gun_data, conn_resp, ref_resp, :fin, data}, @timeout
    assert conn == conn_resp
    assert ref == ref_resp
    JSX.decode!(data)
  end

  defp url(fragment) do
    "/api/v1/#{fragment}"
  end

end
