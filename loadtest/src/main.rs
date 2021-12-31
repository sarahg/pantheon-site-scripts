use goose::prelude::*;

async fn loadtest_index(user: &mut GooseUser) -> GooseTaskResult {
    let _goose_metrics = user.get("").await?;

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), GooseError> {
    GooseAttack::initialize()?
        .register_taskset(taskset!("LoadtestTasks")
            .register_task(task!(loadtest_index))
        )
        .execute()
        .await?
        .print();

    Ok(())
}