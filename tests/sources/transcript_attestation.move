module MyModule::TranscriptAttestation {
    use std::signer;
    use std::string::{Self, String};
    use std::error;
    use aptos_std::table;

    const E_TRANSCRIPT_NOT_FOUND: u64 = 1;
    const E_TRANSCRIPT_ALREADY_EXISTS: u64 = 2;

    struct Transcript has copy, drop, store {
        institution: String,
        transcript_hash: String,
        grade: String,
        attestation_date: u64,
        is_verified: bool,
    }

    struct Registry has key {
        items: table::Table<address, Transcript>,
    }

    /// Publish once by the admin at @MyModule
    public entry fun init(admin: &signer) {
        assert!(signer::address_of(admin) == @MyModule, 100);
        move_to(admin, Registry { items: table::new<address, Transcript>(admin) });
    }

    /// Institution issues attestation for a student (stored in @MyModule’s Registry)
    public entry fun attest_transcript(
        _institution: &signer,
        student_address: address,
        institution_name: String,
        transcript_hash: String,
        grade: String,
        attestation_date: u64
    ) acquires Registry {
        let reg = borrow_global_mut<Registry>(@MyModule);
        assert!(!table::contains(&reg.items, student_address), error::already_exists(E_TRANSCRIPT_ALREADY_EXISTS));
        table::add(
            &mut reg.items,
            student_address,
            Transcript { institution: institution_name, transcript_hash, grade, attestation_date, is_verified: true }
        );
    }

    /// Read-only on-chain view
    #[view]
    public fun verify_transcript(student_address: address): (String, String, String, u64, bool) acquires Registry {
        let reg = borrow_global<Registry>(@MyModule);
        assert!(table::contains(&reg.items, student_address), error::not_found(E_TRANSCRIPT_NOT_FOUND));
        let t = table::borrow(&reg.items, student_address);
        (t.institution, t.transcript_hash, t.grade, t.attestation_date, t.is_verified)
    }
}