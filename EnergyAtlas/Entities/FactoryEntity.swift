import RealityKit
import Combine
import Foundation

/// Encapsulates the Factory model and its smoke-burst timeline handling.
final class FactoryEntity: Entity {
    // MARK: - Internal smokestack & subscriptions
    private var smokestack1: Entity?
    private var smokestack2: Entity?
    private var smokestack3: Entity?
    private var cancellables: [AnyCancellable] = []

    /// Build a new factory instance by cloning the shared prototype.
    /// - Parameter prototype: The pre-loaded `Factory.usda` entity.
    init(cloning prototype: Entity) {
        super.init()
        // Clone entire hierarchy so multiple factories can exist concurrently.
        let clone = prototype.clone(recursive: true)
        self.addChild(clone)

        // Cache smokestacks for quick access.
        smokestack1 = clone.findEntity(named: "Smokestack1")
        smokestack2 = clone.findEntity(named: "Smokestack2")
        smokestack3 = clone.findEntity(named: "Smokestack3")
    }

    required init() {
        fatalError("FactoryEntity should be created with init(cloning:)")
    }

    // MARK: - Timeline notification handling
    /// Begin listening for Reality Composer Pro timeline notifications.
    /// Call this *after* the entity is added to a scene.
    func startListeningForSmokeNotifications() {
        guard let scene = self.scene else { return }

        let sub = NotificationCenter.default.publisher(for: Notification.Name("RealityKit.NotificationTrigger"))
            .sink { [weak self] note in
                guard let self,
                      let info = note.userInfo,
                      let noteScene = info["RealityKit.NotificationTrigger.Scene"] as? RealityKit.Scene,
                      noteScene == scene,
                      let id = info["RealityKit.NotificationTrigger.Identifier"] as? String else { return }

                switch id {
                case "Smoke1": self.triggerBurst(on: self.smokestack1)
                case "Smoke2": self.triggerBurst(on: self.smokestack2)
                case "Smoke3": self.triggerBurst(on: self.smokestack3)
                default: break
                }
            }
        cancellables.append(sub)
    }

    /// Stop listening and clean up.
    func stopListening() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - Helpers
    private func triggerBurst(on entity: Entity?) {
        guard let entity,
              var emitter = entity.components[ParticleEmitterComponent.self] else { return }
        emitter.burst()
        entity.components.set(emitter)
    }
}
