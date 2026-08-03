import { describe, expect, it } from "vitest";
import { isPrivateAddress } from "./public-url";

describe("webhook SSRF koruması", () => {
  it.each([
    "127.0.0.1",
    "10.2.3.4",
    "172.16.0.1",
    "172.31.255.255",
    "192.168.1.2",
    "169.254.10.2",
    "::1",
    "fd00::1",
    "fe80::1",
  ])("%s özel adresini engeller", (address) => {
    expect(isPrivateAddress(address)).toBe(true);
  });
  it.each(["1.1.1.1", "8.8.8.8", "2606:4700:4700::1111"])(
    "%s genel adresine izin verir",
    (address) => {
      expect(isPrivateAddress(address)).toBe(false);
    },
  );
});
