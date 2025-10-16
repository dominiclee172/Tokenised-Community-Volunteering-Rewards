import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { join } from "path";

describe("Contract Structure Tests", () => {
  const contractPath = join(process.cwd(), "contracts", "charity-donation-tracker.clar");
  const contractContent = readFileSync(contractPath, "utf-8");

  it("contains required leaderboard functions", () => {
    expect(contractContent).toContain("update-leaderboard-position");
    expect(contractContent).toContain("get-volunteer-rank");
    expect(contractContent).toContain("get-top-volunteers");
    expect(contractContent).toContain("check-and-award-achievements");
    expect(contractContent).toContain("initialize-achievement-definitions");
    expect(contractContent).toContain("start-new-season");
  });

  it("contains required leaderboard data structures", () => {
    expect(contractContent).toContain("volunteer-leaderboard");
    expect(contractContent).toContain("volunteer-achievements");
    expect(contractContent).toContain("achievement-definitions");
    expect(contractContent).toContain("seasonal-stats");
  });

  it("contains proper error constants", () => {
    expect(contractContent).toContain("ERR_LEADERBOARD_FULL");
    expect(contractContent).toContain("ERR_ACHIEVEMENT_EXISTS");
    expect(contractContent).toContain("ERR_INVALID_RANK");
  });

  it("contains achievement type definitions", () => {
    expect(contractContent).toContain("first-steps");
    expect(contractContent).toContain("dedicated-helper");
    expect(contractContent).toContain("time-champion");
  });

  it("uses proper Clarity v3 syntax", () => {
    expect(contractContent).toContain("define-constant");
    expect(contractContent).toContain("define-fungible-token");
    expect(contractContent).toContain("define-map");
    expect(contractContent).toContain("define-read-only");
    expect(contractContent).toContain("define-public");
    expect(contractContent).toContain("define-private");
  });

  it("implements proper access control", () => {
    expect(contractContent).toContain("CONTRACT_OWNER");
    expect(contractContent).toContain("ERR_NOT_AUTHORIZED");
    expect(contractContent).toContain("is-eq tx-sender CONTRACT_OWNER");
  });
});